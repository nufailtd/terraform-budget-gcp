resource "kubernetes_service_account" "kubeip" {
  metadata {
    name      = "kubeip-serviceaccount"
    namespace = "kube-system"
    annotations = {
      "iam.gke.io/gcp-service-account" = "${google_service_account.kubeip.email}"
    }
  }
  automount_service_account_token = true
}

resource "kubernetes_cluster_role" "kubeip" {
  metadata {
    name = "kubeip"
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get", "list", "watch", "patch"]
  }
}

resource "kubernetes_cluster_role_binding" "kubeip" {
  metadata {
    name = "kubeip"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.kubeip.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.kubeip.metadata.0.name
    namespace = "kube-system"
  }
}

resource "google_service_account_iam_binding" "gsa_ksa_binding" {
  service_account_id = google_service_account.kubeip.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[kube-system/${kubernetes_service_account.kubeip.metadata.0.name}]",
  ]
}


resource "kubernetes_config_map" "kubeip" {
  metadata {
    name      = "kubeip-config"
    namespace = "kube-system"
    labels = {
      app = "kubeip"
    }
  }

  data = {
    KUBEIP_ADDITIONALNODEPOOLS = ""
    KUBEIP_ALLNODEPOOLS        = "false"
    KUBEIP_FORCEASSIGNMENT     = "true"
    KUBEIP_LABELKEY            = "kubeip"
    KUBEIP_LABELVALUE          = "static-ingress"
    KUBEIP_NODEPOOL            = "ingress-pool"
    KUBEIP_SELF_NODEPOOL       = "web-pool"
    KUBEIP_TICKER              = "5"
  }

}



resource "kubernetes_deployment" "kubeip" {
  metadata {
    name      = "kubeip"
    namespace = "kube-system"
    labels = {
      app = "kubeip"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "kubeip"
      }
    }

    template {
      metadata {
        labels = {
          app = "kubeip"
        }
      }

      spec {
        container {
          image = "doitintl/kubeip:latest"
          name  = "kubeip"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.kubeip.metadata.0.name
            }
          }
          /*
          # Use workload identity
          env {
            name  = "GOOGLE_APPLICATION_CREDENTIALS"
            value = "/var/secrets/google/kubeip-key.json"
          }
          */
          resources {
            limits {
              cpu    = "50"
              memory = "50Mi"
            }
            requests {
              cpu    = "50m"
              memory = "50Mi"
            }
          }
          /*
          # Use workload identity
          volume_mount {
            name       = "google-cloud-key"
            mount_path = "/var/secrets/google"
          }
          */
        }
        automount_service_account_token = true
        node_selector = {
          "cloud.google.com/gke-nodepool" = "web-pool"
        }
        restart_policy       = "Always"
        priority_class_name  = "system-node-critical"
        service_account_name = kubernetes_service_account.kubeip.metadata.0.name
        /*
        # Use workload identity
        volume {
          name = "google-cloud-key"
          secret {
            secret_name = kubernetes_secret.kubeip-key.metadata.0.name
          }
        }
        */
      }
    }
  }

  timeouts {
    create = "3m"
    update = "3m"
    delete = "3m"
  }
}