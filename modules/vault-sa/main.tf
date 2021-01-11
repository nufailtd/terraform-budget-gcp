# Query the client configuration for our current service account, which should
# have permission to talk to the GKE cluster since it created it.
data "google_client_config" "current" {}
variable host {}
variable cluster_ca_certificate {}
variable token {}
variable run_post_install {
  default     = false
  description = "Whether to apply components that require existing resources"
}
variable vault_cloudrun_url {
  default = "https://vault:8200"
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
  server_side_planning   = true
}

provider "helm" {
  kubernetes {
    host                   = var.host
    cluster_ca_certificate = var.cluster_ca_certificate
    token                  = var.token
  }

}

resource "kubernetes_role" "vault" {
  metadata {
    name = "vault"
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["*"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "update", "watch"]
  }
}

resource "kubernetes_role_binding" "vault" {
  metadata {
    name = "vault"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.vault.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.vault.metadata.0.name
    namespace = "default"
  }
}

resource "kubernetes_cluster_role_binding" "vault" {
  metadata {
    name = "vault"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.vault.metadata.0.name
    namespace = "default"
  }
}

resource "kubernetes_service_account" "vault" {
  metadata {
    name      = "vault"
    namespace = "default"
  }
}


data "kubernetes_secret" "vault" {
  metadata {
    name = kubernetes_service_account.vault.default_secret_name
  }
}


# Use this to install BanzaiCloud Vault Secrets WebHook
resource "helm_release" "vault-secrets-webhook" {
  name             = "vault-secrets-webhook"
  repository       = "https://kubernetes-charts.banzaicloud.com"
  chart            = "vault-secrets-webhook"
  namespace        = "vswh"
  create_namespace = true
}

# Use this to install Talend Vault Sidecar Injector
resource "helm_release" "vault-sidecar-injector" {
  depends_on = [ kubernetes_service_account.vault ]
  name       = "vault-sidecar-injector"
  repository = "https://talend.github.io/helm-charts-public/stable"
  chart      = "vault-sidecar-injector"

  set {
    name  = "vault.addr"
    value = var.vault_cloudrun_url
  }

  set {
    name  = "vault.ssl.verify"
    value = "true"
  }

  set {
    name  = "mutatingwebhook.annotations.appLabelKey"
    value = "vault.application"
  }

  set {
    name  = "mutatingwebhook.annotations.appServiceLabelKey"
    value = "vault.service"
  }

  set {
    name  = "mutatingwebhook.annotations.keyPrefix"
    value = "sidecar.vault"
  }

  set {
    name  = "resources.requests.cpu"
    value = "50m"
  }

  set {
    name  = "resources.requests.memory"
    value = "64Mi"
  }
  set {
    name  = "resources.limits.cpu"
    value = "50m"
  }

  set {
    name  = "resources.limits.memory"
    value = "64Mi"
  }
}

resource "kubernetes_deployment" "hello-secrets" {
  count    = var.run_post_install == true ? 1 : 0
  metadata {
    name      = "hello-secrets"
    namespace = "default"
    labels = {
      app = "hello-secrets"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "hello-secrets"
      }
    }

    template {
      metadata {
        labels = {
          app = "hello-secrets"
        }
        annotations = {
          "vault.security.banzaicloud.io/vault-addr"                   = var.vault_cloudrun_url
          "vault.security.banzaicloud.io/vault-skip-verify"            = "true"
          "vault.security.banzaicloud.io/vault-role"                   = "kubernetes"
          "vault.security.banzaicloud.io/vault-path"                   = "kubernetes"
          "vault.security.banzaicloud.io/vault-ignore-missing-secrets" = "true"
          "vault.security.banzaicloud.io/vault-ct-configmap"           = "my-config"
          "vault.security.banzaicloud.io/vault-ct-cpu"                 = "25m"
          "vault.security.banzaicloud.io/vault-ct-memory"              = "32Mi"
        }
      }

      spec {
        automount_service_account_token = true
        container {
          image             = "mirror.gcr.io/library/alpine"
          name              = "hello-secrets"
          image_pull_policy = "IfNotPresent"
          command           = ["sh", "-c", "while true; do echo `date +'%Y-%m-%d %H:%M:%S'` : $GCP_SECRET_KEY; cat /vault/secrets/config; sleep 5; done"]
          env {
            name  = "GCP_SECRET_KEY"
            value = "vault:secret/data/accounts/gcp#GCP_SECRET_KEY"
          }

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
      }
    }
  }

  timeouts {
    create = "2m"
    update = "2m"
    delete = "2m"
  }
}


resource "kubernetes_config_map" "example" {
  metadata {
    name = "my-config"
  }

  data = {
    "config.hcl" = <<-EOF
    vault {
      retry {
        backoff = "1s"
      }
    }
    template {
      contents = <<EOH
        {{- with secret "secret/data/accounts/gcp" }}
        GCP_SECRET_KEY: {{ .Data.data.GCP_SECRET_KEY }}
        {{ end }}
      EOH
      destination = "/vault/secrets/config"
      command     = "/bin/sh -c \"ls & cat /vault/secrets/config\""
    }
EOF
  }

}


output "token" {
  description = "Generated Service Account Token"
  value       = lookup(data.kubernetes_secret.vault.data, "token")
}

output "ca_crt" {
  description = "Generated Service Account ca.crt"
  value       = lookup(data.kubernetes_secret.vault.data, "ca.crt")
}
