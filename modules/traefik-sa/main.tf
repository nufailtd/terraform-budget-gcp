# Query the client configuration for our current service account, which should
# have permission to talk to the GKE cluster since it created it.
data "google_client_config" "current" {}
variable host {}
variable cluster_ca_certificate {}
variable token {}
variable project_id {}
variable client_email {}
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
  server_side_planning   = true
}

provider "helm" {
  kubernetes {
    host                   = var.host
    cluster_ca_certificate = var.cluster_ca_certificate
    token                  = var.token
  }

}

resource "kubernetes_cluster_role" "traefik-container-vm" {
  metadata {
    name = "traefik-container-vm"
  }

  rule {
    api_groups = [""]
    resources  = ["services", "endpoints", "secrets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["ingresses/status"]
    verbs      = ["update"]
  }

  rule {
    api_groups = ["traefik.containo.us"]
    resources  = ["middlewares", "ingressroutes", "traefikservices", "ingressroutetcps", "ingressrouteudps", "tlsoptions", "tlsstores", "serverstransports"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "traefik-container-vm" {
  metadata {
    name = "traefik-container-vm"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.traefik-container-vm.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.traefik-container-vm.metadata.0.name
    namespace = "default"
  }
}

resource "kubernetes_service_account" "traefik-container-vm" {
  metadata {
    name      = "traefik-container-vm"
    namespace = "default"
  }
}

resource "google_secret_manager_secret" "secret" {
  secret_id = "traefik_token"
  project   = var.project_id

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "secret-version" {

  secret      = google_secret_manager_secret.secret.id
  secret_data = lookup(data.kubernetes_secret.traefik-container-vm.data, "token")
}

resource "google_secret_manager_secret_iam_member" "member" {

  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.client_email}"
  secret_id = google_secret_manager_secret.secret.id
}


data "kubernetes_secret" "traefik-container-vm" {
  metadata {
    name = kubernetes_service_account.traefik-container-vm.default_secret_name
  }
}

# Use this to install Traefik CRDs
resource "helm_release" "traefik" {
  name       = "traefik"
  repository = "https://helm.traefik.io/traefik"
  chart      = "traefik"

  set {
    name  = "deployment.enabled"
    value = "false"
  }

  set {
    name  = "service.enabled"
    value = "false"
  }

  set {
    name  = "ingressRoute.dashboard.enabled"
    value = "false"
  }
  
  set {
    name  = "image.tag"
    value = "v2.4.0"
  }

}

resource "kubernetes_namespace" "whoami" {
  metadata {
    name = "whoami"
  }
}

resource "kubernetes_service" "whoami" {
  metadata {
    name      = "whoami"
    namespace = kubernetes_namespace.whoami.metadata.0.name
    labels = {
      app = "whoami"
    }
  }
  spec {
    selector = {
      app = kubernetes_deployment.whoami.metadata.0.labels.app
    }
    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_service" "whoami_default" {
  metadata {
    name = "whoami"
  }
  spec {
    type          = "ExternalName"
    external_name = "whoami.whoami.svc.cluster.local"
  }
}

resource "kubernetes_deployment" "whoami" {
  metadata {
    name      = "whoami"
    namespace = kubernetes_namespace.whoami.metadata.0.name
    labels = {
      app = "whoami"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "whoami"
      }
    }

    template {
      metadata {
        labels = {
          app = "whoami"
        }
      }

      spec {
        container {
          image             = "containous/whoami"
          name              = "whoami"
          image_pull_policy = "IfNotPresent"

          resources {
            limits {
              cpu    = "10"
              memory = "10Mi"
            }
            requests {
              cpu    = "10m"
              memory = "10Mi"
            }
          }
        }
        node_selector = {
          "cloud.google.com/gke-nodepool" = "web-pool"
        }
      }
    }
  }

  timeouts {
    create = "3m"
    update = "3m"
    delete = "3m"
  }
}

resource "kubernetes_ingress" "traefik" {
  metadata {
    name      = "traefik"
    namespace = kubernetes_namespace.whoami.metadata.0.name
    annotations = {
      "cert-manager.io/cluster-issuer"                   = "letsencrypt-live"
      "kubernetes.io/ingress.class"                      = "traefik-cert-manager"
      "traefik.ingress.kubernetes.io/router.entrypoints" = "web, websecure"
      "traefik.ingress.kubernetes.io/router.tls"         = "true"

    }
  }

  spec {
    rule {
      host = "test.${var.domain}"
      http {
        path {
          backend {
            service_name = "whoami"
            service_port = 80
          }
        }
      }
    }

    tls {
      secret_name = "traefik-http01-cert"
      hosts = [
        "test.${var.domain}",
      ]
    }
  }
}

output "traefik_token" {
  description = "Generated Service Account Token"
  value       = "sm://${var.project_id}/${google_secret_manager_secret.secret.secret_id}"
}

output "ca_crt" {
  description = "Generated Service Account ca.crt"
  value       = lookup(data.kubernetes_secret.traefik-container-vm.data, "ca.crt")
}
