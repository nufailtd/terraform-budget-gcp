## This file contains module that have been disabled but can be run as an exercise to the reader.
## The primary reason for not using these modules is the cost.
## To run any of these, remove the opening and closing /* */


# Encrypt etcd data in gke
/*
module "kms" {
  source              = "terraform-google-modules/kms/google"
  project_id          = var.project_id
  keyring             = var.project_id
  key_rotation_period = "604800s"
  location            = var.region
  keys                = ["gke-secrets-key"]
  set_owners_for      = ["gke-secrets-key"]
  owners              = ["serviceAccount:project-service-account@${var.project_id}.iam.gserviceaccount.com"]
  # keys can be destroyed by Terraform
  prevent_destroy = false
}
*/

# Assign a static ip to ephemeral gke nodes
/*
module "kubeip" {
  source = "./kubeip"

  project_id             = var.project_id
  zone                   = module.gke.location
  host                   = module.gke_auth.host
  cluster_ca_certificate = module.gke_auth.cluster_ca_certificate
  token                  = module.gke_auth.token
}
*/

# Allows internet access for nodes in our private gke cluster
/*
module "cloud-nat" {
  source                             = "terraform-google-modules/cloud-nat/google"
  version                            = "~> 1.2"
  project_id                         = var.project_id
  region                             = var.region
  create_router                      = "true"
  router                             = "gke-router"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  network                            = module.gcp-network.network_self_link
  subnetworks = [
    {
      name                     = module.gcp-network.subnets_self_links[0]
      source_ip_ranges_to_nat  = ["ALL_IP_RANGES"]
      secondary_ip_range_names = []
    }
  ]
}
*/