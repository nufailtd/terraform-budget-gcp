resource "kubernetes_manifest" "clusterissuer_self_signed" {
  count    = var.run_post_install == true ? 1 : 0
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "cert-manager.io/v1alpha2"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name" = "self-signed"
    }
    "spec" = {
      "selfSigned" = {}
    }
  }
}

resource "kubernetes_manifest" "clusterissuer_letsencrypt_test" {
  count    = var.run_post_install == true ? 1 : 0
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "cert-manager.io/v1alpha2"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name" = "letsencrypt-test"
    }
    "spec" = {
      "acme" = {
        "email" = "admin@${var.domain}"
        "privateKeySecretRef" = {
          "name" = "test-issuer-account-key"
        }
        "server" = "https://acme-staging-v02.api.letsencrypt.org/directory"
        "solvers" = [
          {
            "http01" = {
              "ingress" = {
                "class" = "traefik-cert-manager"
              }
            }
          },
          {
            "dns01" = {
              "clouddns" = {
                "project" = var.project_id
              }
            },
            "selector" = {
              "dnsNames" = [
                "${var.domain}",
                "*.${var.domain}",
              ]
            }
          },
        ]
      }
    }
  }
}

resource "kubernetes_manifest" "clusterissuer_letsencrypt_live" {
  count    = var.run_post_install == true ? 1 : 0
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "cert-manager.io/v1alpha2"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name" = "letsencrypt-live"
    }
    "spec" = {
      "acme" = {
        "email" = "admin@${var.domain}"
        "privateKeySecretRef" = {
          "name" = "live-issuer-account-key"
        }
        "server" = "https://acme-v02.api.letsencrypt.org/directory"
        "solvers" = [
          {
            "http01" = {
              "ingress" = {
                "class" = "traefik-cert-manager"
              }
            }
          },
          {
            "dns01" = {
              "clouddns" = {
                "project" = "${var.project_id}"
              }
            },
            "selector" = {
              "dnsNames" = [
                "${var.domain}",
                "*.${var.domain}",
              ]
            }
          },
        ]
      }
    }
  }
}

resource "kubernetes_manifest" "certificate_self_signed_cert" {
  count    = var.run_post_install == true ? 1 : 0
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "cert-manager.io/v1alpha2"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "self-signed-cert"
      "namespace" = "default"
    }
    "spec" = {
      "commonName" = "${var.domain}"
      "dnsNames" = [
        "${var.domain}",
        "*.${var.domain}",
      ]
      "issuerRef" = {
        "kind" = "ClusterIssuer"
        "name" = "self-signed"
      }
      "secretName" = "self-signed-cert"
    }
  }
}

resource "kubernetes_manifest" "certificate_test_wildcard_cert" {
  count    = var.run_post_install == true ? 1 : 0
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "cert-manager.io/v1alpha2"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "test-wildcard-cert"
      "namespace" = "default"
    }
    "spec" = {
      "commonName" = "${var.domain}"
      "dnsNames" = [
        "${var.domain}",
        "*.${var.domain}",
      ]
      "issuerRef" = {
        "kind" = "ClusterIssuer"
        "name" = "letsencrypt-test"
      }
      "secretName" = "test-wildcard-cert"
    }
  }
}

resource "kubernetes_manifest" "certificate_live_wildcard_cert" {
  count    = var.run_post_install == true ? 1 : 0
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "cert-manager.io/v1alpha2"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "live-wildcard-cert"
      "namespace" = "default"
    }
    "spec" = {
      "commonName" = "${var.domain}"
      "dnsNames" = [
        "${var.domain}",
        "*.${var.domain}",
      ]
      "issuerRef" = {
        "kind" = "ClusterIssuer"
        "name" = "letsencrypt-live"
      }
      "secretName" = "live-wildcard-cert"
    }
  }
}

# Test certificates

resource "kubernetes_manifest" "certificate_whoami_cert" {
  count    = var.run_post_install == true ? 1 : 0
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "cert-manager.io/v1alpha2"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "whoami-cert"
      "namespace" = "whoami"
    }
    "spec" = {
      "commonName" = "whoami.${var.domain}"
      "dnsNames" = [
        "whoami.${var.domain}",
      ]
      "issuerRef" = {
        "kind" = "ClusterIssuer"
        "name" = "letsencrypt-live"
      }
      "secretName" = "whoami-http01-cert"
    }
  }
}


resource "kubernetes_manifest" "certificate_dash_cert" {
  count    = var.run_post_install == true ? 1 : 0
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "cert-manager.io/v1alpha2"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "dash-cert"
      "namespace" = "default"
    }
    "spec" = {
      "commonName" = "dash.${var.domain}"
      "dnsNames" = [
        "dash.${var.domain}",
      ]
      "issuerRef" = {
        "kind" = "ClusterIssuer"
        "name" = "letsencrypt-live"
      }
      "secretName" = "dash-http01-cert"
    }
  }
}

