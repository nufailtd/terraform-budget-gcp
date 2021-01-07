# Query the client configuration for our current service account, which should
# have permission to talk to the GKE cluster since it created it.
data "google_client_config" "current" {}
variable host {}
variable cluster_ca_certificate {}
variable token {}
variable project_id {}
variable zone {}

provider "google" {
  project = var.project_id
  zone    = var.zone
}

provider "google-beta" {
  project = var.project_id
  zone    = var.zone
}


# This file contains all the interactions with Kubernetes
provider "kubernetes" {
  load_config_file       = false
  host                   = var.host
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.token
}

resource "google_compute_address" "static-ingress" {
  name     = "static-ingress"
  project  = var.project_id
  provider = google-beta

  # address labels are a beta feature
  labels = {
    kubeip = "static-ingress"
  }
}


resource "google_project_iam_custom_role" "kubeip" {
  role_id = "kubeip"
  title   = "kubeip Role"

  project = var.project_id

  permissions = [
    "compute.addresses.list",
    "compute.instances.addAccessConfig",
    "compute.instances.deleteAccessConfig",
    "compute.instances.get",
    "compute.instances.list",
    "compute.projects.get",
    "container.clusters.get",
    "container.clusters.list",
    "resourcemanager.projects.get",
    "compute.networks.useExternalIp",
    "compute.subnetworks.useExternalIp",
    "compute.addresses.use",
  ]
}

# kubeip service account
resource "google_service_account" "kubeip" {
  account_id = "kubeip-serviceaccount"
  project    = var.project_id
  depends_on = [google_project_iam_custom_role.kubeip]
}

resource "google_project_iam_member" "iam_member_kubeip" {

  role       = "projects/${var.project_id}/roles/kubeip"
  project    = var.project_id
  member     = "serviceAccount:kubeip-serviceaccount@${var.project_id}.iam.gserviceaccount.com"
  depends_on = [google_service_account.kubeip]
}

/*
# Uncomment if workload-identity does not work
resource "google_service_account_key" "kubeip-key" {
  service_account_id = google_service_account.kubeip.name
}

# Write the secret
resource "kubernetes_secret" "kubeip-key" {
  metadata {
    name      = "kubeip-key"
    namespace = "kube-system"
  }

  data = {
    "kubeip-key.json" = base64decode(google_service_account_key.kubeip-key.private_key)
  }
}
*/