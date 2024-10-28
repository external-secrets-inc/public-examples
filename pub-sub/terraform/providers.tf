terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }

    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.0"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = "us-central1" ## Change Accordingly
}

provider "kubectl" {
  config_path = "~/.kube/config" ## Change Accordingly
  config_context = "kind-kind"
}
