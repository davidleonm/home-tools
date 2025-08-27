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

resource "helm_release" "otel_operator" {
  name       = "opentelemetry-operator"
  chart      = "opentelemetry-operator"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  namespace  = kubernetes_namespace.namespace.metadata[0].name

  set {
    name  = "admissionWebhooks.certManager.enabled"
    value = "true"
  }

  set {
    name  = "admissionWebhooks.autoGenerateCert.enabled"
    value = "true"
  }

  set {
    name  = "manager.collectorImage.repository"
    value = "otel/opentelemetry-collector-k8s"
  }

  set {
    name  = "manager.createRbacPermissions"
    value = "true"
  }
}

resource "kubernetes_manifest" "otel_collector" {
  manifest = {
    apiVersion = "opentelemetry.io/v1beta1"
    kind       = "OpenTelemetryCollector"

    metadata = {
      name      = "opentelemetry"
      namespace = kubernetes_namespace.namespace.metadata[0].name
    }

    # Docs -> https://github.com/open-telemetry/opentelemetry-operator/blob/main/docs/api/opentelemetrycollectors.md#opentelemetryiov1beta1
    spec = {
      mode   = "statefulset"
      config = yamldecode(file("${path.module}/configs/open-telemetry-collector.yaml"))

      env = [
        {
          name  = "GRAFANA_CLOUD_OTLP_ENDPOINT"
          value = var.grafana_endpoint
        },
        {
          name  = "GRAFANA_CLOUD_API_KEY"
          value = var.grafana_token
        },
        {
          name  = "GRAFANA_CLOUD_INSTANCE_ID"
          value = var.grafana_instance_id
        }
      ]
    }
  }
}

resource "kubernetes_service" "otel_collector_nodeport" {
  metadata {
    name      = "opentelemetry-collector"
    namespace = kubernetes_namespace.namespace.metadata[0].name
  }

  spec {
    type = "NodePort"

    selector = {
      "app.kubernetes.io/name" = "opentelemetry-collector"
    }

    port {
      name        = "otlp-grpc"
      port        = 4317
      target_port = 4317
      node_port   = 34317
      protocol    = "TCP"
    }

    port {
      name        = "otlp-http"
      port        = 4318
      target_port = 4318
      node_port   = 34318
      protocol    = "TCP"
    }
  }
}