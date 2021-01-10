variable project_id {}
variable zone {}
variable region {}
variable gke_serviceaccount {}
variable pomerium_sa {}
variable proxy_server {}
variable domain {}
data "google_client_config" "current" {}

provider "google" {
  project = var.project_id
  zone    = var.zone
}

provider "google-beta" {
  project = var.project_id
  zone    = var.zone
}

locals {
  image_tag = "v1"
}

resource "null_resource" "ghost_image" {
  triggers = {
    image      = "us.gcr.io/${var.project_id}/ghost:${local.image_tag}"
    dockerfile = filemd5("${path.module}/build/Dockerfile")
  }
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
        gcloud builds submit \
        --project ${var.project_id} \
        --tag ${self.triggers.image} \
        ${path.module}/build
    EOT
  }
}

resource "null_resource" "static_ip_image" {
  triggers = {
    image      = "us.gcr.io/${var.project_id}/test:${local.image_tag}"
    dockerfile = filemd5("${path.module}/static_ip/Dockerfile")
  }
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
        gcloud builds submit \
        --project ${var.project_id} \
        --tag ${self.triggers.image} \
        ${path.module}/static_ip
    EOT
  }
}

resource "google_cloud_run_service" "my-service" {

  depends_on = [null_resource.ghost_image]
  name       = "my-service"
  location   = "us-central1"

  template {
    spec {
      service_account_name = var.gke_serviceaccount
      containers {
        image = null_resource.ghost_image.triggers.image
        ports {
          container_port = 2368
        }

        env {
          name  = "dockerfile"
          value = null_resource.ghost_image.triggers.dockerfile
        }

        env {
          name  = "url"
          value = "https://blog.${var.domain}"
        }

        env {
          name  = "PROXY_SERVER"
          value = var.proxy_server
        }

        env {
          name  = "PROXY_USER"
          value = "sm://${var.project_id}/proxy_user"
        }

        env {
          name  = "PROXY_PASS"
          value = "sm://${var.project_id}/proxy_password"
        }

        env {
          name  = "database__client"
          value = "mysql"
        }

        env {
          name  = "database__connection__host"
          value = "127.0.0.1"
        }

        env {
          name  = "database__connection__port"
          value = "3306"
        }

        env {
          name  = "database__connection__database"
          value = "container-db"
        }

        env {
          name  = "database__connection__user"
          value = "sm://${var.project_id}/mysql_user"
        }

        env {
          name  = "database__connection__password"
          value = "sm://${var.project_id}/mysql_password"
        }

      }
      timeout_seconds = 180
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "1"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

}

/*
resource "google_cloud_run_service_iam_member" "allUsers" {
  service  = google_cloud_run_service.my-service.name
  location = google_cloud_run_service.my-service.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
*/

# Create service account access
data "google_iam_policy" "auth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "serviceAccount:${var.gke_serviceaccount}",
      "serviceAccount:${var.pomerium_sa}",
    ]
  }
}
# Enable access for Cloud Run service
resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.my-service.location
  project     = google_cloud_run_service.my-service.project
  service     = google_cloud_run_service.my-service.name
  policy_data = data.google_iam_policy.auth.policy_data
}

output "url" {
  value = google_cloud_run_service.my-service.status[0].url
}