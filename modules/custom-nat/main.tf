# Query the client configuration for our current service account, which should
# have permission to talk to the GKE cluster since it created it.
data "google_client_config" "current" {}
variable host {}
variable zone {}
variable region {}
variable project_id {}
variable network {}
variable subnetwork {}
variable hop_instance {}

provider "google" {
  project = var.project_id
  zone    = var.zone
}

provider "google-beta" {
  project = var.project_id
  zone    = var.zone
}

/*
resource "google_compute_route" "gke-master-default-gw" {
  name             = "master-default-gw"
  dest_range       = "${var.host}/32"
  network          = var.network
  next_hop_gateway = "default-internet-gateway"
  tags             = ["gke-kluster"]
  priority         = 700
}
*/

resource "google_compute_route" "nat-gateway" {
  name                   = "nat-gateway"
  project                = var.project_id
  dest_range             = "0.0.0.0/0"
  network                = var.network
  next_hop_instance      = var.hop_instance
  next_hop_instance_zone = var.zone
  tags                   = ["gke-kluster"]
  priority               = 800
}
