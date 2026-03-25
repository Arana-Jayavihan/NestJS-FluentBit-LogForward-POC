# =============================================================================
# Namespaces
# =============================================================================

resource "kubernetes_namespace" "app" {
  metadata {
    name = var.app_namespace

    labels = {
      name        = var.app_namespace
      managed-by  = "terraform"
      environment = "poc"
    }
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.monitoring_namespace

    labels = {
      name        = var.monitoring_namespace
      managed-by  = "terraform"
      environment = "poc"
    }
  }
}

# =============================================================================
# FluentBit Secrets ConfigMap
# =============================================================================

resource "kubernetes_config_map" "fluentbit_secrets" {
  metadata {
    name      = "fluentbit-secrets"
    namespace = kubernetes_namespace.monitoring.metadata[0].name

    labels = {
      app        = "fluent-bit"
      managed-by = "terraform"
    }
  }

  data = {
    AZURE_CLIENT_ID     = var.azure_client_id
    AZURE_CLIENT_SECRET = var.azure_client_secret
    AZURE_TENANT_ID     = var.azure_tenant_id
    AZURE_DCE_URL       = var.azure_dce_url
    AZURE_DCR_ID        = var.azure_dcr_id
    AZURE_TABLE_NAME    = var.azure_table_name
  }
}

# =============================================================================
# FluentBit Helm Release
# =============================================================================

resource "helm_release" "fluent_bit" {
  name       = "fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  version    = var.fluentbit_chart_version
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  wait    = true
  timeout = 300

  values = [
    templatefile("${path.module}/templates/fluentbit-values.yaml.tpl", {
      replica_count       = var.fluentbit_replica_count
      image_tag           = var.fluentbit_image_tag
      tcp_port            = var.fluentbit_tcp_port
      azure_enabled       = var.azure_enabled
      azure_client_id     = var.azure_client_id
      azure_client_secret = var.azure_client_secret
      azure_tenant_id     = var.azure_tenant_id
      azure_dce_url       = var.azure_dce_url
      azure_dcr_id        = var.azure_dcr_id
      azure_table_name    = var.azure_table_name
    })
  ]

  depends_on = [
    kubernetes_config_map.fluentbit_secrets
  ]
}

# =============================================================================
# NestJS Application Helm Release
# =============================================================================

resource "helm_release" "nest_api" {
  name      = "nest-api"
  chart     = "${path.module}/../poc-stack-helm/charts/nest-api"
  namespace = kubernetes_namespace.app.metadata[0].name

  wait    = true
  timeout = 6000

  set {
    name  = "replicaCount"
    value = var.nestjs_replica_count
  }

  set {
    name  = "image.repository"
    value = var.nestjs_image_repository
  }

  set {
    name  = "image.tag"
    value = var.nestjs_image_tag
  }

  set {
    name  = "image.pullPolicy"
    value = var.nestjs_image_pull_policy
  }

  set {
    name  = "service.port"
    value = var.nestjs_service_port
  }

  # FluentBit connection (cross-namespace)
  set {
    name  = "fluentbit.host"
    value = "fluent-bit.${var.monitoring_namespace}.svc.cluster.local"
  }

  set {
    name  = "fluentbit.port"
    value = var.fluentbit_tcp_port
  }

  depends_on = [
    helm_release.fluent_bit
  ]
}
