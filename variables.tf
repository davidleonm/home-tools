variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "time_zone" {
  description = "Time zone to set in the containers"
  type        = string
}

variable "config_volume_size" {
  description = "Config size to use as maximum"
  type        = string
}

variable "downloads_volume_size" {
  description = "Downloads size to use as maximum"
  type        = string
}

variable "environment_root_folder" {
  description = "Root folder for environment files"
  type        = string
}

variable "grafana_token" {
  description = "Grafana API token for authentication"
  type        = string
  sensitive   = true
}

variable "grafana_instance_id" {
  description = "Grafana instance ID for telemetry"
  type        = string
  sensitive   = true
}

variable "grafana_endpoint" {
  description = "Grafana endpoint for telemetry"
  type        = string
  sensitive   = true
}