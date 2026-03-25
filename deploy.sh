#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NESTJS_DIR="${SCRIPT_DIR}/nest-js-fb-log-inter-poc"
K8S_DIR="${SCRIPT_DIR}/k8s"
HELM_CHART_DIR="${SCRIPT_DIR}/poc-stack-helm/charts/nest-api"

# Check if we're in nix shell
check_dependencies() {
    log_info "Checking dependencies..."

    local missing=()
    for cmd in minikube kubectl helm docker; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Missing dependencies: ${missing[*]}"
        log_info "Run 'nix develop' to enter the development shell with all dependencies"
        exit 1
    fi

    log_info "All dependencies found"
}

# Start minikube if not running
start_minikube() {
    log_info "Checking minikube status..."

    if ! minikube status &> /dev/null; then
        log_info "Starting minikube..."
        minikube start --driver=docker
    else
        log_info "Minikube is already running"
    fi

    # Configure docker to use minikube's docker daemon
    log_info "Configuring docker to use minikube's daemon..."
    eval $(minikube docker-env)
}

# Build and load Docker image
build_image() {
    log_info "Building NestJS Docker image..."

    cd "${NESTJS_DIR}"
    docker build -t nest-api:latest .

    log_info "Docker image built successfully: nest-api:latest"
}

# Create namespaces
create_namespaces() {
    log_info "Creating namespaces..."

    kubectl create namespace app --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

    log_info "Namespaces 'app' and 'monitoring' created"
}

# Install FluentBit secrets ConfigMap
install_fluentbit_secrets() {
    log_info "Installing FluentBit secrets ConfigMap..."

    kubectl apply -f "${K8S_DIR}/fluentbit-secrets-configmap.yaml"

    log_info "FluentBit secrets ConfigMap installed in monitoring namespace"
}

# Add Helm repo and install FluentBit
install_fluentbit() {
    log_info "Adding FluentBit Helm repository..."

    helm repo add fluent https://fluent.github.io/helm-charts/ || true
    helm repo update

    log_info "Installing FluentBit in monitoring namespace..."

    # Uninstall if exists
    helm uninstall fluent-bit -n monitoring 2>/dev/null || true

    # Install FluentBit
    helm install fluent-bit fluent/fluent-bit \
        -n monitoring \
        -f "${K8S_DIR}/fluentbit-values.yaml" \
        --wait

    log_info "FluentBit installed successfully"
}

# Deploy NestJS application
deploy_nestjs() {
    log_info "Deploying NestJS application to app namespace..."

    # Uninstall if exists
    helm uninstall nest-api -n app 2>/dev/null || true

    # Install NestJS app
    helm install nest-api "${HELM_CHART_DIR}" \
        -n app \
        --set image.repository=nest-api \
        --set image.tag=latest \
        --set image.pullPolicy=Never \
        --wait

    log_info "NestJS application deployed successfully"
}

# Verify deployment
verify_deployment() {
    log_info "Verifying deployment..."

    echo ""
    log_info "=== Pods in 'app' namespace ==="
    kubectl get pods -n app

    echo ""
    log_info "=== Pods in 'monitoring' namespace ==="
    kubectl get pods -n monitoring

    echo ""
    log_info "=== Services in 'app' namespace ==="
    kubectl get svc -n app

    echo ""
    log_info "=== Services in 'monitoring' namespace ==="
    kubectl get svc -n monitoring
}

# Test log forwarding
test_logs() {
    log_info "Testing log forwarding..."

    # Get the NestJS pod name
    local nest_pod=$(kubectl get pods -n app -l app.kubernetes.io/name=nest-api -o jsonpath='{.items[0].metadata.name}')
    local fb_pod=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=fluent-bit -o jsonpath='{.items[0].metadata.name}')

    echo ""
    log_info "NestJS Pod: ${nest_pod}"
    log_info "FluentBit Pod: ${fb_pod}"

    # Port forward NestJS service
    log_info "Starting port-forward to test the API..."
    kubectl port-forward -n app svc/nest-api 3000:3000 &
    local pf_pid=$!
    sleep 2

    # Make a test request
    log_info "Making test request to /health endpoint..."
    curl -s http://localhost:3000/health | jq . || curl -s http://localhost:3000/health

    # Kill port-forward
    kill $pf_pid 2>/dev/null || true

    echo ""
    log_info "Checking FluentBit logs for received data..."
    kubectl logs -n monitoring "${fb_pod}" --tail=20
}

# Print usage
print_usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  all           Run full deployment (default)"
    echo "  check         Check dependencies"
    echo "  minikube      Start minikube"
    echo "  build         Build Docker image"
    echo "  namespaces    Create namespaces"
    echo "  secrets       Install FluentBit secrets ConfigMap"
    echo "  fluentbit     Install FluentBit"
    echo "  app           Deploy NestJS application"
    echo "  verify        Verify deployment"
    echo "  test          Test log forwarding"
    echo "  clean         Clean up all resources"
}

# Clean up
cleanup() {
    log_warn "Cleaning up all resources..."

    helm uninstall nest-api -n app 2>/dev/null || true
    helm uninstall fluent-bit -n monitoring 2>/dev/null || true
    kubectl delete namespace app 2>/dev/null || true
    kubectl delete namespace monitoring 2>/dev/null || true

    log_info "Cleanup complete"
}

# Main
main() {
    local cmd="${1:-all}"

    case "$cmd" in
        all)
            check_dependencies
            start_minikube
            build_image
            create_namespaces
            install_fluentbit_secrets
            install_fluentbit
            deploy_nestjs
            verify_deployment
            echo ""
            log_info "Deployment complete!"
            log_info "Run '$0 test' to test log forwarding"
            ;;
        check)
            check_dependencies
            ;;
        minikube)
            check_dependencies
            start_minikube
            ;;
        build)
            check_dependencies
            start_minikube
            build_image
            ;;
        namespaces)
            create_namespaces
            ;;
        secrets)
            install_fluentbit_secrets
            ;;
        fluentbit)
            install_fluentbit
            ;;
        app)
            deploy_nestjs
            ;;
        verify)
            verify_deployment
            ;;
        test)
            test_logs
            ;;
        clean)
            cleanup
            ;;
        help|--help|-h)
            print_usage
            ;;
        *)
            log_error "Unknown command: $cmd"
            print_usage
            exit 1
            ;;
    esac
}

main "$@"
