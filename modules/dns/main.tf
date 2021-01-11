# Query the client configuration for our current service account, which should
# have permission to talk to the GKE cluster since it created it.
data "google_client_config" "current" {}
variable host {}
variable cluster_ca_certificate {}
variable token {}
variable domain {}
variable project_id {}
variable domain_filter {
  default = ""
}
variable check_interval {
  default = "20m"
}
variable traefik_ip {}
variable traefik_ip_private {}
variable "dns_auth" {}

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
    host                   = var.host
    cluster_ca_certificate = var.cluster_ca_certificate
    token                  = var.token
  }

}

resource "helm_release" "external-dns" {
  name       = "external-dns"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"
  set {
    name  = "image.registry"
    value = "k8s.gcr.io"
  }

  set {
    name  = "image.repository"
    value = "external-dns/external-dns"
  }

  set {
    name  = "image.tag"
    value = "v0.7.4"
    # https://github.com/kubernetes-sigs/external-dns/issues/449
  }

  set {
    name  = "replicas"
    value = "1"
  }

  set {
    name  = "podAntiAffinityPreset"
    value = "hard"
  }

  set {
    name  = "podLabels.app"
    value = "external-dns"
    type  = "string"
  }

  dynamic "set_sensitive" {
    for_each = var.dns_auth
    iterator = dns
    content {
      name  = dns.value["name"]
      value = dns.value["value"]
    }
  }

  set {
    name  = "service.type"
    value = "ClusterIP"
  }

  set {
    name  = "service.externalIPs"
    value = "{${var.traefik_ip}}"
  }

  set {
    name  = "txtOwnerId"
    value = var.domain
  }

  set {
    name  = "domainFilters"
    value = "{${var.domain_filter == "" ? var.domain : var.domain_filter}}"
  }

  set {
    name  = "policy"
    value = "sync"
  }

  set {
    name  = "txtPrefix"
    value = "exdns."
  }

  set {
    name  = "logLevel"
    value = "debug"
  }

  set {
    name  = "interval"
    value = var.check_interval
  }

  set {
    name  = "serviceAccount.name"
    value = "external-dns"
  }

  set {
    name  = "serviceAccount.annotations.iam\\.gke\\.io/gcp-service-account"
    value = "external-dns@${var.project_id}.iam.gserviceaccount.com"
    type  = "string"
  }

  # https://github.com/hashicorp/terraform-provider-helm/issues/586#issuecomment-690341801
  set {
    name  = "extraEnv[0].name"
    value = "EXTERNAL_DNS_TXT_WILDCARD_REPLACEMENT"
  }

  set {
    name  = "extraEnv[0].value"
    value = "wild"
  }

  /*
  # Disabled because it points to Internal clusterIP
  set {
    name  = "publishInternalServices"
    value = "true"
  }  
  
  set {
    name  = "service.annotations.external-dns\\.alpha\\.kubernetes\\.io/hostname"
    value = var.domain
    type  = "string"
  }

  set {
    name  = "service.annotations.external-dns\\.alpha\\.kubernetes\\.io/ttl"
    value = "60"
    type  = "string"
  }

  set {
    name  = "service.annotations.external-dns\\.alpha\\.kubernetes\\.io/target"
    value = var.traefik_ip
    type  = "string"
  }
  */

}

# Creates wildcard domain CNAME Record
resource "kubernetes_service" "external-dns-domains" {
  metadata {
    name = "external-dns-domains"
    annotations = {
      "external-dns.alpha.kubernetes.io/hostname" = "*.${var.domain}"
      "external-dns.alpha.kubernetes.io/ttl"      = "300"
    }
  }
  spec {
    type          = "ExternalName"
    external_name = var.domain
  }
}

# Creates BASE domain A Record
resource "kubernetes_service" "external-dns-domain" {
  metadata {
    name = "external-dns-domain"
    annotations = {
      "external-dns.alpha.kubernetes.io/hostname" = var.domain
      "external-dns.alpha.kubernetes.io/ttl"      = "60"
    }
  }
  spec {
    type          = "ExternalName"
    external_name = var.traefik_ip
  }
}

