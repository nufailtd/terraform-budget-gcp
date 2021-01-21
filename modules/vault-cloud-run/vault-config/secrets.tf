resource "random_password" "example_secret" {
  length  = 30
  special = false
}

resource "time_sleep" "wait_60_seconds" {
  depends_on = [vault_mount.kvv2]

  create_duration = "60s"
}

resource "vault_generic_secret" "example" {
  depends_on = [time_sleep.wait_60_seconds]
  path       = "secret/accounts/gcp"

  data_json = <<EOT
{
  "GCP_SECRET_KEY": "${random_password.example_secret.result}"
}
EOT
}

