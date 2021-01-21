variable run_post_install {
  default     = false
  description = "Whether to apply components that require existing resources"
}

variable domain {}

resource "kubernetes_manifest" "ingressroute_foo" {
  count    = var.run_post_install == true ? 1 : 0
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "traefik.containo.us/v1alpha1"
    "kind"       = "IngressRoute"
    "metadata" = {
      "name"      = "foo"
      "namespace" = "whoami"
    }
    "spec" = {
      "entryPoints" = [
        "web",
        "websecure",
      ]
      "routes" = [
        {
          "kind"  = "Rule"
          "match" = "Host(`foo.${var.domain}`)"
          "services" = [
            {
              "name" = "whoami"
              "port" = 80
            },
          ]
        },
      ]
    }
  }
}

resource "kubernetes_manifest" "ingressroute_whoami" {
  count    = var.run_post_install == true ? 1 : 0
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "traefik.containo.us/v1alpha1"
    "kind"       = "IngressRoute"
    "metadata" = {
      "name"      = "whoami"
      "namespace" = "whoami"
    }
    "spec" = {
      "entryPoints" = [
        "web",
        "websecure",
      ]
      "routes" = [
        {
          "kind"  = "Rule"
          "match" = "Host(`whoami.${var.domain}`)"
          "services" = [
            {
              "name" = "whoami"
              "port" = 80
            },
          ]
        },
      ]
      "tls" = {
        "secretName" = "whoami-http01-cert"
      }
    }
  }
}

resource "kubernetes_manifest" "ingressroute_traefik_dashboard" {
  count    = var.run_post_install == true ? 1 : 0
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "traefik.containo.us/v1alpha1"
    "kind"       = "IngressRoute"
    "metadata" = {
      "name"      = "traefik-dashboard"
      "namespace" = "default"
    }
    "spec" = {
      "entryPoints" = [
        "web",
        "websecure",
      ]
      "routes" = [
        {
          "kind"  = "Rule"
          "match" = "Host(`dash.${var.domain}`)"
          "services" = [
            {
              "kind" = "TraefikService"
              "name" = "api@internal"
            },
          ]
        },
      ]
      "tls" = {
        "secretName" = "dash-http01-cert"
      }
    }
  }
}

resource "kubernetes_manifest" "tlsstore_default" {
  count    = var.run_post_install == true ? 1 : 0
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "traefik.containo.us/v1alpha1"
    "kind"       = "TLSStore"
    "metadata" = {
      "name"      = "default"
      "namespace" = "default"
    }
    "spec" = {
      "defaultCertificate" = {
        "secretName" = "live-wildcard-cert"
      }
    }
  }
}

resource "kubernetes_manifest" "middleware_pomerium_auth_middleware" {
  count    = var.run_post_install == true ? 1 : 0
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "traefik.containo.us/v1alpha1"
    "kind"       = "Middleware"
    "metadata" = {
      "name"      = "pomerium-auth-middleware"
      "namespace" = "default"
    }
    "spec" = {
      "forwardAuth" = {
        "address" = "http://pomerium-proxy.default"
        "authResponseHeaders" = [
          "x-pomerium-jwt-assertion",
          "x-pomerium-claim-email",
          "x-pomerium-claim-groups",
          "x-pomerium-claim-user",
          "x-pomerium-claim-nickname",
          "x-pomerium-claim-name",
          "x-pomerium-claim-picture",
          "x-pomerium-claim-email_verified",
        ]
        "tls" = {
          "insecureSkipVerify" = true
        }
        "trustForwardHeader" = true
      }
    }
  }
}

