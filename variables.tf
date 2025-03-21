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
  description = "Token to connect to Grafana"
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  type    = string
  default = "microk8s"
}

variable "grafana_destinations_prometheus_url" {
  type    = string
  default = "https://prometheus-prod-24-prod-eu-west-2.grafana.net/api/prom/push"
}

variable "grafana_destinations_prometheus_username" {
  type    = number
  default = 2337443
}

variable "grafana_destinations_loki_url" {
  type    = string
  default = "https://logs-prod-012.grafana.net/loki/api/v1/push"
}

variable "grafana_destinations_loki_username" {
  type    = number
  default = 1164399
}

variable "grafana_destinations_otlp_url" {
  type    = string
  default = "https://tempo-prod-10-prod-eu-west-2.grafana.net:443"
}

variable "grafana_destinations_otlp_username" {
  type    = number
  default = 1158713
}

variable "grafana_destinations_pyroscope_url" {
  type    = string
  default = "https://profiles-prod-002.grafana.net:443"
}

variable "grafana_destinations_pyroscope_username" {
  type    = number
  default = 1206602
}
