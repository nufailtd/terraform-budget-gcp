variable vault_address {}
variable root_token_decrypt_command {}
variable host {}
variable cluster_ca_certificate {}
variable domain {}
variable project {}
variable location {}
variable email {}
variable oidc_config {}
variable interpreter {
  default     = "bash"
  description = "Shell used to run decrypt command"
}
variable "ca_crt" {
  description = "Kubernetes ca.crt."
  type        = string
  default     = ""
}

variable "token" {
  description = "Kubernetes service account auth token for vault."
  type        = string
  default     = ""
}

provider "google" {
  project = var.project
  zone    = var.location
}

# The source `data.google_kms_secret` does not populate vault provider token when running plan
data "external" "vault_token" {
  program = [var.interpreter, "-c", <<-EOF
  echo "{\"vault_token\":\"$(${var.root_token_decrypt_command})\"}"
EOF
  ]
}

provider vault {
  address = var.vault_address
  token   = data.external.vault_token.result["vault_token"]
}

resource "vault_jwt_auth_backend" "oidc" {
  description        = "OIDC Terraform JWT auth backend"
  path               = "oidc"
  default_role       = "default"
  type               = "oidc"
  oidc_discovery_url = join(",", [for x in var.oidc_config : x.value if x.name == "authenticate.idp.url"])
  # Alternative: var.oidc_config[index(var.oidc_config.*.name, "authenticate.idp.url")].value
  oidc_client_id     = join(",", [for x in var.oidc_config : x.value if x.name == "authenticate.idp.clientID"])
  oidc_client_secret = join(",", [for x in var.oidc_config : x.value if x.name == "authenticate.idp.clientSecret"])
}

resource "vault_jwt_auth_backend_role" "default" {
  backend               = vault_jwt_auth_backend.oidc.path
  role_name             = "default"
  token_policies        = [vault_policy.read_secrets.name, vault_policy.allow_ssh.name, vault_policy.pki_int.name]
  oidc_scopes           = ["openid", "profile", "email"]
  user_claim            = "email"
  role_type             = "oidc"
  allowed_redirect_uris = ["${var.vault_address}/ui/vault/auth/oidc/oidc/callback", "https://vault.${var.domain}/ui/vault/auth/oidc/oidc/callback"]
  bound_claims          = { "email" : join(",", [var.email]) }
}

resource "vault_jwt_auth_backend_role" "admin" {
  backend               = vault_jwt_auth_backend.oidc.path
  role_name             = "admin"
  token_policies        = [vault_policy.read_secrets.name, vault_policy.allow_secrets.name, vault_policy.allow_secret_backends.name, vault_policy.allow_auth.name, vault_policy.allow_auth_backends.name, vault_policy.allow_policy.name, vault_policy.read_policy.name, vault_policy.read_health.name, vault_policy.read_metrics.name, vault_policy.read_sys.name, vault_policy.read_self.name, vault_policy.allow_ssh.name, vault_policy.pki_admin.name]
  oidc_scopes           = ["openid", "profile", "email"]
  user_claim            = "email"
  role_type             = "oidc"
  allowed_redirect_uris = ["${var.vault_address}/ui/vault/auth/oidc/oidc/callback", "https://vault.${var.domain}/ui/vault/auth/oidc/oidc/callback"]
  bound_claims          = { "email" : join(",", [var.email]) }
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_role" "kubernetes" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "kubernetes"
  bound_service_account_names      = ["default", "vault-secrets-webhook"]
  bound_service_account_namespaces = ["default", "vswh"]
  token_ttl                        = 3600
  token_policies                   = [vault_policy.allow_secrets.name]
  # audience                       = var.vault_address
}

resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = var.host
  kubernetes_ca_cert     = var.ca_crt
  token_reviewer_jwt     = var.token
  issuer                 = "kubernetes/serviceaccount"
  disable_iss_validation = "true"
}

