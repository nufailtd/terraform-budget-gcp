
data "archive_file" "src" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/generated/src.zip"
}

resource "google_storage_bucket_object" "archive" {
  name   = "${data.archive_file.src.output_md5}.zip"
  bucket = google_storage_bucket.vault.name
  source = "${path.module}/generated/src.zip"
}

resource "google_cloudfunctions_function" "function" {
  name        = "vault-${lower(random_id.vault.hex)}-init"
  description = "A Cloud Function to auto-initialize vault."
  runtime     = "go111"

  environment_variables = {
    GCS_BUCKET_NAME   = google_storage_bucket.vault.name,
    KMS_KEY_ID        = google_kms_crypto_key.vault.id,
    CHECK_INTERVAL    = "-1",
    VAULT_SKIP_VERIFY = true
    VAULT_ADDR        = google_cloud_run_service.default.status[0].url
  }

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.vault.name
  source_archive_object = google_storage_bucket_object.archive.name
  trigger_http          = true
  entry_point           = "VaultInit"
  service_account_email = google_service_account.vault.email
}

resource "time_static" "iam_update" {
  triggers = {
    vault_id = google_cloud_run_service.default.status.0.latest_created_revision_name
    archive  = data.archive_file.src.output_md5
  }
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = google_cloudfunctions_function.function.project
  region         = google_cloudfunctions_function.function.region
  cloud_function = google_cloudfunctions_function.function.name

  role   = "roles/cloudfunctions.invoker"
  member = "serviceAccount:${google_service_account.vault.email}"
}

/*
# Requires appengine enabled on project
# Seems a bit heavy handed to solve the problem.
resource "google_cloud_scheduler_job" "job" {
  count    = var.run_post_install == true ? 0 : 0
  name             = "vault-init-scheduler"
  description      = "Trigger the ${google_cloudfunctions_function.function.name} Cloud Function every minute."
  schedule         = ""
  attempt_deadline = "320s"

  http_target {
    http_method = "GET"
    uri         = google_cloudfunctions_function.function.https_trigger_url

    oidc_token {
      service_account_email = google_service_account.vault.email
      audience              = google_cloudfunctions_function.function.https_trigger_url
    }
  }
  
}
*/

data "google_service_account_id_token" "oidc" {
  depends_on             = [google_cloudfunctions_function_iam_member.invoker]
  target_audience        = google_cloudfunctions_function.function.https_trigger_url
  target_service_account = google_service_account.vault.email
}

data "http" "vaultinit" {
  depends_on = [google_cloudfunctions_function_iam_member.invoker]
  url        = google_cloudfunctions_function.function.https_trigger_url
  request_headers = {
    Authorization = "Bearer ${data.google_service_account_id_token.oidc.id_token}"
  }
}

# Enable Public Access after successful init
resource "google_cloud_run_service_iam_member" "allusers" {
  depends_on = [data.http.vaultinit]
  location   = google_cloud_run_service.default.location
  project    = google_cloud_run_service.default.project
  service    = google_cloud_run_service.default.name
  role       = "roles/run.invoker"
  member     = "allUsers"
}

# Set minimal permissions for service account
resource "google_kms_key_ring_iam_member" "decrypt" {
  key_ring_id = google_kms_key_ring.vault.id
  role        = "roles/cloudkms.cryptoKeyDecrypter"
  member      = "serviceAccount:project-service-account@${var.project}.iam.gserviceaccount.com"

  /* Conditionally set to expire
  condition {
    title       = "expires_after_120s"
    description = "Expiring after 120s"
    expression  = "request.time < timestamp(\"${time_static.iam_update.rfc3339}\") + duration(\"120s\")"
  }
  */
}

output "root_token_decrypt_command" {
  value = "gsutil cat gs://${google_storage_bucket.vault.name}/root-token.enc | base64 --decode | gcloud kms decrypt --key ${google_kms_crypto_key.vault.self_link} --ciphertext-file - --plaintext-file -"
}
