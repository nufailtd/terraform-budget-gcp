resource "vault_mount" "kvv2" {
  path        = "secret"
  type        = "kv-v2"
  description = "Key/Value V2 - with versioning"

  options = {
    version      = 2
    max_versions = 5
    cas_enabled  = false
  }
}

resource "vault_mount" "ssh" {
  type = "ssh"
  path = "ssh-client-signer"
}

resource "vault_mount" "pki_int" {
  type                      = "pki"
  path                      = "pki_int"
  description               = "Root CA used to sign certs"
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 86400
}
/*
resource "vault_ssh_secret_backend_ca" "ssh" {
  backend = vault_mount.ssh.path
}
*/
resource "vault_ssh_secret_backend_role" "ssh" {
  name                    = "ssh"
  backend                 = vault_mount.ssh.path
  key_type                = "ca"
  default_user            = "ubuntu"
  allowed_users           = "*"
  cidr_list               = "0.0.0.0/0"
  allow_user_certificates = "true"
}

resource "vault_pki_secret_backend_root_cert" "root" {

  backend = vault_mount.pki_int.path

  type                 = "exported"
  common_name          = var.domain
  ttl                  = "315360000"
  format               = "pem"
  private_key_format   = "der"
  key_type             = "rsa"
  key_bits             = 4096
  exclude_cn_from_sans = true
  ou                   = "My OU"
  organization         = "My organization"
}

resource "vault_pki_secret_backend_config_urls" "config_urls" {
  backend                 = vault_mount.pki_int.path
  issuing_certificates    = ["${var.vault_address}/v1/pki_int/ca"]
  crl_distribution_points = ["${var.vault_address}/v1/pki_int/crl"]
}

resource "vault_pki_secret_backend_role" "default" {
  backend = vault_mount.pki_int.path
  name    = "default"
  allowed_domains = [
    "localhost", "pod", "svc", "default"
  ]
  allow_subdomains   = true
  allow_bare_domains = true
  allowed_other_sans = [
  ]
  key_usage = [
    "DigitalSignature",
    "KeyAgreement",
    "KeyEncipherment",
  ]
}

resource "vault_pki_secret_backend_role" "org" {
  backend = vault_mount.pki_int.path
  name    = "org"
  allowed_domains = [
    "localhost", "pod", "svc", "default", var.domain
  ]
  allow_subdomains = true
  key_usage = [
    "DigitalSignature",
    "KeyAgreement",
    "KeyEncipherment",
  ]
}
