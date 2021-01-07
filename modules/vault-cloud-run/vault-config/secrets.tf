resource "random_password" "example_secret" {
  length  = 30
  special = false
}


resource "vault_generic_secret" "example" {
  path = "secret/accounts/gcp"

  data_json = <<EOT
{
  "GCP_SECRET_KEY": "${random_password.example_secret.result}"
}
EOT
}

