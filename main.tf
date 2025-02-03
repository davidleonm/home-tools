provider "kubernetes" {}

terraform {
  required_version = ">= 1.10.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.34.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
  }

  backend "kubernetes" {}
}

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
  docker_image   = "jlesage/jdownloader-2:v22.11.1"
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