resource "vault_policy" "read_secrets" {
  name = "read_secrets"

  policy = <<EOT
path "secret/*" {
  capabilities = ["read", "list"]
}
EOT
}

resource "vault_policy" "allow_secrets" {
  name = "allow_secrets"

  policy = <<EOT
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOT
}

resource "vault_policy" "allow_secret_backends" {
  name = "allow_secret_backends"

  policy = <<EOT
path "sys/mounts*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOT
}

resource "vault_policy" "allow_auth" {
  name = "allow_auth"

  policy = <<EOT
path "auth/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOT
}

resource "vault_policy" "read_auth_backends" {
  name = "read_auth_backends"

  policy = <<EOT
path "sys/auth" {
  capabilities = ["read"]
}
EOT
}

resource "vault_policy" "allow_auth_backends" {
  name = "allow_auth_backends"

  policy = <<EOT
path "sys/auth*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOT
}

resource "vault_policy" "allow_policy" {
  name = "allow_policy"

  policy = <<EOT
path "sys/policies/acl*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOT
}

resource "vault_policy" "read_policy" {
  name = "read_policy"

  policy = <<EOT
path "sys/policies/acl*" {
  capabilities = ["read"]
}
EOT
}

resource "vault_policy" "read_health" {
  name = "read_health"

  policy = <<EOT
path "sys/health" {
  capabilities = ["read", "sudo"]
}
EOT
}

resource "vault_policy" "read_metrics" {
  name = "read_metrics"

  policy = <<EOT
path "sys/metrics" {
  capabilities = ["read"]
}
EOT
}

resource "vault_policy" "read_sys" {
  name = "read_sys"

  policy = <<EOT
path "sys/capabilities" {
  capabilities = ["create", "update"]
}
EOT
}

resource "vault_policy" "read_self" {
  name = "read_self"

  policy = <<EOT
path "sys/capabilities-self" {
  capabilities = ["create", "update"]
}
EOT
}

resource "vault_policy" "allow_ssh" {
  name = "allow_ssh"

  policy = <<EOT
path "ssh-client-signer*" {
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}
EOT
}

resource "vault_policy" "pki_admin" {
  name = "pki_admin"

  policy = <<EOT
path "pki*" {
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}
path "pki/*" {
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}
EOT
}

resource "vault_policy" "pki_int" {
  name = "pki_int"

  policy = <<EOT
path "pki_int/issue/*" {
  capabilities = ["create", "update"]
}

path "pki_int/*" {
  capabilities = ["list"]
}

path "pki_int/certs" {
  capabilities = ["list"]
}

path "pki_int/revoke" {
  capabilities = ["create", "update"]
}

path "pki_int/tidy" {
  capabilities = ["create", "update"]
}

path "pki/cert/ca" {
  capabilities = ["read"]
}

path "pki*" {
  capabilities = [ "list" ]
}
EOT
}
