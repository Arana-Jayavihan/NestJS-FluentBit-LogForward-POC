# =============================================================================
# Kubernetes Configuration
# =============================================================================

variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kubeconfig_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = "minikube"
}

# =============================================================================
# Namespace Configuration
# =============================================================================

variable "app_namespace" {
  description = "Namespace for the NestJS application"
  type        = string
  default     = "app"
}

variable "monitoring_namespace" {
  description = "Namespace for FluentBit and monitoring tools"
  type        = string
  default     = "monitoring"
}

# =============================================================================
# NestJS Application Configuration
# =============================================================================

variable "nestjs_image_repository" {
  description = "Docker image repository for NestJS app"
  type        = string
  default     = "nest-api"
}

variable "nestjs_image_tag" {
  description = "Docker image tag for NestJS app"
  type        = string
  default     = "latest"
}

variable "nestjs_image_pull_policy" {
  description = "Image pull policy for NestJS app"
  type        = string
  default     = "Never" # Use 'Never' for local minikube images
}

variable "nestjs_replica_count" {
  description = "Number of NestJS replicas"
  type        = number
  default     = 1
}

variable "nestjs_service_port" {
  description = "Service port for NestJS app"
  type        = number
  default     = 3000
}

# =============================================================================
# FluentBit Configuration
# =============================================================================

variable "fluentbit_chart_version" {
  description = "FluentBit Helm chart version"
  type        = string
  default     = "0.49.0"
}

variable "fluentbit_image_tag" {
  description = "FluentBit image tag"
  type        = string
  default     = "3.2.2"
}

variable "fluentbit_replica_count" {
  description = "Number of FluentBit replicas"
  type        = number
  default     = 1
}

variable "fluentbit_tcp_port" {
  description = "TCP port for FluentBit to receive logs"
  type        = number
  default     = 9000
}

# =============================================================================
# Azure Log Analytics Configuration (Optional)
# =============================================================================

variable "azure_enabled" {
  description = "Enable Azure Log Analytics output"
  type        = bool
  default     = false
}

variable "azure_client_id" {
  description = "Azure client ID for Log Analytics"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_client_secret" {
  description = "Azure client secret for Log Analytics"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_tenant_id" {
  description = "Azure tenant ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_dce_url" {
  description = "Azure Data Collection Endpoint URL"
  type        = string
  default     = ""
}

variable "azure_dcr_id" {
  description = "Azure Data Collection Rule ID"
  type        = string
  default     = ""
}

variable "azure_table_name" {
  description = "Azure Log Analytics custom table name"
  type        = string
  default     = ""
}
