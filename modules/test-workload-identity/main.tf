data "google_client_config" "current" {}
variable host {}
variable cluster_ca_certificate {}
variable token {}
variable ksa {}
variable ksa_namespace {
  default     = "default"
  description = "Kubernetes service account namespace"
}
variable run_post_install {
  default     = false
  description = "Whether to apply components that require existing resources"
}

# This file contains all the interactions with Kubernetes
provider "kubernetes" {
  load_config_file       = false
  host                   = var.host
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.token
}

resource "kubernetes_pod" "test" {
  count    = var.run_post_install == true ? 1 : 0
  metadata {
    name      = "workload-identity-test"
    namespace = var.ksa_namespace
  }

  spec {
    container {
      image   = "google/cloud-sdk:slim"
      name    = "workload-identity-test"
      command = ["sleep", "infinity"]

    }

    service_account_name = var.ksa
  }
}
