# Query the client configuration for our current service account, which should
# have permission to talk to the GKE cluster since it created it.
data "google_client_config" "current" {}
variable host {}
variable cluster_ca_certificate {}
variable token {}
variable domain {}
variable project_id {}
variable zone {}
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

provider "kubernetes-alpha" {
  host                   = var.host
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.token
}

provider "helm" {
  kubernetes {
    load_config_file       = false
    host                   = var.host
    cluster_ca_certificate = var.cluster_ca_certificate
    token                  = var.token
  }

}

variable "extraArgs" {
  description = "List of additional arguments for cert-manager"
  type        = list
  default = [
    "--dns01-recursive-nameservers-only",
    "--dns01-recursive-nameservers=8.8.8.8:53\\,1.1.1.1:53",
  ]
}

resource "helm_release" "cert-manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  create_namespace = true
  namespace        = "cert-manager"
  verify           = false

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "ingressShim.defaultIssuerName"
    value = "letsencrypt-live"
  }

  set {
    name  = "ingressShim.defaultIssuerKind"
    value = "ClusterIssuer"
  }

  set {
    name  = "ingressShim.defaultIssuerGroup"
    value = "cert-manager.io"
  }

  set {
    name  = "podDnsPolicy"
    value = "None"
  }

  set {
    name  = "podDnsConfig.nameservers[0]"
    value = "10.0.0.67"
  }

  set {
    name = "extraArgs"
    // https://github.com/hashicorp/terraform-provider-helm/issues/92#issuecomment-407807183
    value = "{${join(",", var.extraArgs)}}"
  }

}

