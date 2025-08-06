provider "kubernetes" {}

terraform {
  required_version = ">= 1.10.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.34.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
    }
  }

  backend "kubernetes" {}
}

provider "helm" {
  kubernetes {
    config_path    = ".kube/config"
    config_context = "microk8s"
  }
}