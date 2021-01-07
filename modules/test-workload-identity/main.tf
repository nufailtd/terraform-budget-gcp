data "google_client_config" "current" {}
variable host {}
variable cluster_ca_certificate {}
variable token {}
variable ksa {}

# This file contains all the interactions with Kubernetes
provider "kubernetes" {
  load_config_file       = false
  host                   = var.host
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.token
}

resource "kubernetes_pod" "test" {
  metadata {
    name = "workload-identity-test"
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
