# Query the client configuration for our current service account, which should
# have permission to talk to the GKE cluster since it created it.
data "google_client_config" "current" {}
variable host {}
variable cluster_ca_certificate {}
variable token {}
variable project_id {}
variable zone {}
variable domain {}
variable cloudrun_url {}
variable vault_cloudrun_url {}
variable email {}
variable oidc_config {
  default = []
}

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

provider "kubernetes-alpha" {
  host                   = var.host
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.token
}


provider "helm" {
  debug = true
  kubernetes {
    host                   = var.host
    cluster_ca_certificate = var.cluster_ca_certificate
    token                  = var.token
  }
}

data "template_file" "pomerium_values" {
  template = file("${path.module}/pomerium-values.yml")
  vars = {
    domain             = var.domain
    cloudrun_url       = var.cloudrun_url
    vault_cloudrun_url = var.vault_cloudrun_url
    email              = var.email
  }
}

resource "random_password" "shared_secret" {
  length = 32
}

resource "random_password" "cookie_secret" {
  length = 32
}

resource "helm_release" "pomerium" {
  name         = "pomerium"
  repository   = "https://helm.pomerium.io"
  chart        = "pomerium"
  timeout      = 300
  force_update = false # Set to true if Error: cannot re-use a name that is still in use

  values = [data.template_file.pomerium_values.rendered]

  set {
    name  = "config.sharedSecret"
    value = base64encode(random_password.shared_secret.result)
  }

  set {
    name  = "config.cookieSecret"
    value = base64encode(random_password.cookie_secret.result)
  }

  dynamic "set_sensitive" {
    for_each = var.oidc_config
    iterator = oidc
    content {
      name  = oidc.value["name"]
      value = oidc.value["value"]
    }
  }

}
