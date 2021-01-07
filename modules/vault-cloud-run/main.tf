provider "google" {
  project = var.project
  zone    = var.location
  region  = var.location
}

provider "random" {}

locals {
  vault_config = jsonencode(
    {
      "storage" = {
        "gcs" = {
          "bucket"     = local.vault_storage_bucket_name
          "ha_enabled" = "false"
        }
      },
      "seal" = {
        "gcpckms" = {
          "project"    = var.project,
          "region"     = var.location,
          "key_ring"   = local.vault_kms_keyring_name,
          "crypto_key" = google_kms_crypto_key.vault.name
        }
      },
      "default_lease_ttl" = "168h",
      "max_lease_ttl"     = "720h",
      "disable_mlock"     = "true",
      "listener" = {
        "tcp" = {
          "address"     = "0.0.0.0:8080",
          "tls_disable" = "1"
        }
      },
      "ui" = var.vault_ui
    }
  )
  vault_kms_keyring_name    = var.vault_kms_keyring_name != "" ? var.vault_kms_keyring_name : "${var.name}-${lower(random_id.vault.hex)}-kr"
  vault_storage_bucket_name = var.vault_storage_bucket_name != "" ? var.vault_storage_bucket_name : "${var.name}-${lower(random_id.vault.hex)}-bucket"
}


resource "random_id" "vault" {
  byte_length = 2
}

resource "google_service_account" "vault" {
  account_id   = var.vault_service_account_id
  display_name = "Vault Service Account for KMS auto-unseal"
}

resource "google_storage_bucket" "vault" {
  name          = local.vault_storage_bucket_name
  force_destroy = var.bucket_force_destroy
}

resource "google_storage_bucket_iam_member" "member" {
  bucket = google_storage_bucket.vault.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.vault.email}"
}

# Create a KMS key ring
resource "google_kms_key_ring" "vault" {
  name     = local.vault_kms_keyring_name
  location = var.location
}

# Create a crypto key for the key ring, rotate daily
resource "google_kms_crypto_key" "vault" {
  name            = "${var.name}-key"
  key_ring        = google_kms_key_ring.vault.self_link
  rotation_period = var.vault_kms_key_rotation
}

# Add the service account to the Keyring
resource "google_kms_key_ring_iam_member" "vault" {
  key_ring_id = google_kms_key_ring.vault.id
  role        = "roles/owner"
  member      = "serviceAccount:${google_service_account.vault.email}"
}

resource "google_cloud_run_service" "default" {
  name                       = var.name
  location                   = var.location
  autogenerate_revision_name = true

  metadata {
    namespace = var.project
  }

  template {
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = 1 # HA not Supported
      }
    }
    spec {
      service_account_name  = google_service_account.vault.email
      container_concurrency = var.container_concurrency
      containers {
        # Specifying args seems to require the command / entrypoint
        image   = var.vault_image
        command = ["/usr/local/bin/docker-entrypoint.sh"]
        args    = ["server"]

        env {
          name  = "SKIP_SETCAP"
          value = "true"
        }

        env {
          name  = "VAULT_LOCAL_CONFIG"
          value = local.vault_config
        }

        env {
          name  = "VAULT_API_ADDR"
          value = var.vault_api_addr
        }

        env {
          name  = "VAULT_SECRET_SHARES"
          value = var.vault_recovery_shares
        }

        env {
          name  = "VAULT_SECRET_THRESHOLD"
          value = var.vault_recovery_threshold
        }

        resources {
          limits = {
            "cpu"    = "1000m"
            "memory" = "256Mi"
          }
          requests = {}
        }
      }
    }
  }
}

# Create initial private access
resource "google_cloud_run_service_iam_member" "auth" {
  location = google_cloud_run_service.default.location
  project  = google_cloud_run_service.default.project
  service  = google_cloud_run_service.default.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.vault.email}"
}

output "app_url" {
  value = google_cloud_run_service.default.status[0].url
}