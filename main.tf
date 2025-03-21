locals {
  hostname = "raspberrypi"
}

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_role" "pod_executor" {
  metadata {
    name      = "pod-executor"
    namespace = kubernetes_namespace.namespace.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["create"]
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get"]
  }
}

resource "kubernetes_storage_class" "home_tools_storage" {
  metadata {
    name = "home-tools-storage"
  }

  storage_provisioner = "microk8s.io/hostpath"
  reclaim_policy      = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"

  parameters = {
    pvDir = var.environment_root_folder
  }
}

module "jdownloader" {
  source = "github.com/davidleonm/cicd-pipelines/terraform/modules/service"

  namespace      = kubernetes_namespace.namespace.metadata[0].name
  name           = "jdownloader"
  docker_image   = "jlesage/jdownloader-2"
  container_port = 5800
  external_port  = 30058
  sa_role        = kubernetes_role.pod_executor.metadata[0].name
  hostname       = local.hostname

  volumes = [
    {
      name               = "config"
      storage_class_name = kubernetes_storage_class.home_tools_storage.metadata[0].name
      host_path          = "${var.environment_root_folder}/config"
      container_path     = "/config"
      read_only          = false
      capacity           = var.config_volume_size
    },
    {
      name               = "downloads"
      storage_class_name = kubernetes_storage_class.home_tools_storage.metadata[0].name
      host_path          = "${var.environment_root_folder}/downloads"
      container_path     = "/output"
      read_only          = false
      capacity           = var.downloads_volume_size
    }
  ]

  environment_variables = {
    SECURE_CONNECTION = "1"
    TZ                = var.time_zone
  }
}

resource "helm_release" "grafana-k8s-monitoring" {
  name             = "grafana-k8s-monitoring"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "k8s-monitoring"
  namespace        = var.namespace
  create_namespace = true
  atomic           = true
  timeout          = 300

  values = [file("${path.module}/values.yaml")]

  set {
    name  = "cluster.name"
    value = var.cluster_name
  }

  set {
    name  = "destinations[0].url"
    value = var.grafana_destinations_prometheus_url
  }

  set_sensitive {
    name  = "destinations[0].auth.username"
    value = var.grafana_destinations_prometheus_username
  }

  set_sensitive {
    name  = "destinations[0].auth.password"
    value = var.grafana_token
  }

  set {
    name  = "destinations[1].url"
    value = var.grafana_destinations_loki_url
  }

  set_sensitive {
    name  = "destinations[1].auth.username"
    value = var.grafana_destinations_loki_username
  }

  set_sensitive {
    name  = "destinations[1].auth.password"
    value = var.grafana_token
  }

  set {
    name  = "destinations[2].url"
    value = var.grafana_destinations_otlp_url
  }

  set_sensitive {
    name  = "destinations[2].auth.username"
    value = var.grafana_destinations_otlp_username
  }

  set_sensitive {
    name  = "destinations[2].auth.password"
    value = var.grafana_token
  }

  set {
    name  = "destinations[3].url"
    value = var.grafana_destinations_pyroscope_url
  }

  set_sensitive {
    name  = "destinations[3].auth.username"
    value = var.grafana_destinations_pyroscope_username
  }

  set_sensitive {
    name  = "destinations[3].auth.password"
    value = var.grafana_token
  }
}