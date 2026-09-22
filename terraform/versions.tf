# Terraform configuration for the k3d-demo platform.
#
# This module provisions the in-cluster platform components that
# scripts/create_cluster.sh installs via Helm + kubectl. It intentionally
# does NOT create the k3d cluster itself (that stays in the shell scripts)
# and does NOT create the ArgoCD Application manifests (those are a separate
# GitOps step: scripts/deploy_argocd_apps.sh).
#
# State is stored locally under this directory (terraform/terraform.tfstate),
# so it can be checked out / shared per-cluster without a remote backend.
terraform {
  required_version = ">= 1.16.3"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.30.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.0"
    }
  }

  # Store state in this directory (terraform/terraform.tfstate).
  backend "local" {
    path = "terraform.tfstate"
  }
}
