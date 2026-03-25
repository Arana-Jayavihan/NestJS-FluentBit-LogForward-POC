# =============================================================================
# Namespace Outputs
# =============================================================================

output "app_namespace" {
  description = "Name of the application namespace"
  value       = kubernetes_namespace.app.metadata[0].name
}

output "monitoring_namespace" {
  description = "Name of the monitoring namespace"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

# =============================================================================
# NestJS Application Outputs
# =============================================================================

output "nestjs_release_name" {
  description = "Helm release name for NestJS app"
  value       = helm_release.nest_api.name
}

output "nestjs_release_status" {
  description = "Helm release status for NestJS app"
  value       = helm_release.nest_api.status
}

output "nestjs_service_endpoint" {
  description = "Internal service endpoint for NestJS app"
  value       = "nest-api.${var.app_namespace}.svc.cluster.local:${var.nestjs_service_port}"
}

# =============================================================================
# FluentBit Outputs
# =============================================================================

output "fluentbit_release_name" {
  description = "Helm release name for FluentBit"
  value       = helm_release.fluent_bit.name
}

output "fluentbit_release_status" {
  description = "Helm release status for FluentBit"
  value       = helm_release.fluent_bit.status
}

output "fluentbit_service_endpoint" {
  description = "Internal service endpoint for FluentBit TCP input"
  value       = "fluent-bit.${var.monitoring_namespace}.svc.cluster.local:${var.fluentbit_tcp_port}"
}

# =============================================================================
# Useful Commands
# =============================================================================

output "kubectl_commands" {
  description = "Useful kubectl commands for testing"
  value = {
    port_forward_nestjs   = "kubectl port-forward -n ${var.app_namespace} svc/nest-api ${var.nestjs_service_port}:${var.nestjs_service_port}"
    view_fluentbit_logs   = "kubectl logs -n ${var.monitoring_namespace} deployment/fluent-bit -f"
    get_pods_app          = "kubectl get pods -n ${var.app_namespace}"
    get_pods_monitoring   = "kubectl get pods -n ${var.monitoring_namespace}"
    test_health_endpoint  = "curl http://localhost:${var.nestjs_service_port}/health"
  }
}
