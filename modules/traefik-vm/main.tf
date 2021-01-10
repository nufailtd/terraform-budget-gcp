variable network {}
variable "cluster_cidr" {
  description = "Cluster CIDR to route traffic for."
  type        = string
  default     = "10.0.0.0/17"
}

variable "subnet_ranges" {
  description = "Cluster Subnet Ranges to be allowed in firewall rules."
  type        = list
  default     = ["0.0.0.0/0"]
}

data "google_client_config" "current" {}

provider "google" {
  project = var.project_id
  zone    = var.zone
}

locals {
  instance_name = format("%s-%s", var.instance_name, substr(md5(module.gce-container.container.image), 0, 8))
  config_path   = "/etc/traefik"
  endpoint      = var.endpoint
  private_ip    = cidrhost(var.cluster_cidr, 67)
}

module "gce-container" {
  source = "terraform-google-modules/container-vm/google"

  cos_image_name = var.cos_image_name

  container = {
    image = "traefik:v2.3.5"
    /*
    command = [
      "tail"
    ]
    */
    args = [
      "--accesslog=true",
      "--api.insecure=true",
      "--entrypoints.web.address=:80",
      "--entryPoints.web.forwardedHeaders.insecure=true",
      "--entrypoints.websecure.address=:443",
      "--entryPoints.websecure.forwardedHeaders.insecure=true",
      "--entrypoints.tcp.address=:8800",
      "--entrypoints.udp.address=:9090/udp",
      "--entrypoints.ping.address=:8082",
      "--ping.entrypoint=ping",
      "--providers.docker.exposedbydefault=false",
      "--providers.docker=true",
      "--api.dashboard=true",
      "--providers.docker.endpoint=unix:///var/run/docker.sock",
      "--log.level=INFO",
      "--accesslog=true",
      "--providers.file.directory=/etc/traefik",
      "--providers.kubernetescrd",
      "--providers.kubernetesingress",
      "--providers.kubernetesIngress.ingressClass=traefik-cert-manager",
      "--entrypoints.websecure.http.tls=true",
      "--entrypoints.web.http.redirections.entryPoint.scheme=https",
      "--entrypoints.web.http.redirections.entryPoint.to=:443",
      "--entrypoints.web.http.redirections.entrypoint.priority=100",
    ]

    securityContext = {
      privileged : false
    }

    restart_policy = "OnFailure"

    tty : false

    env = [
      {
        name  = "KUBERNETES_SERVICE_HOST"
        value = local.endpoint
      },
      {
        name  = "KUBERNETES_SERVICE_PORT"
        value = "443"
      },
    ]

    volumeMounts = [
      {
        mountPath = "/etc/traefik/"
        name      = "traefik"
        readOnly  = false
      },
      {
        mountPath = "/var/run/docker.sock"
        name      = "docker"
        readOnly  = true
      },
      {
        mountPath = "/var/run/secrets/kubernetes.io/serviceaccount/"
        name      = "kubernetes"
        readOnly  = true
      },
    ]
  }

  volumes = [
    {
      name = "traefik"
      hostPath = {
        path = "/etc/traefik"
      }
    },
    {
      name = "kubernetes"
      hostPath = {
        path = "/run/k8s-conf"
      }
    },
    {
      name = "docker"
      hostPath = {
        path = "/var/run/docker.sock"
      }
    },
  ]

  restart_policy = "Always"
}

data "template_file" "cloud-config" {
  depends_on = [ google_secret_manager_secret_version.secret-version ]
  template   = "${file("${path.module}/cloud-config.yml")}"

  vars = {
    custom_var     = var.cloud_init_custom_var
    instance_name  = local.instance_name
    ca_crt         = var.ca_crt
    traefik_token  = var.traefik_token
    startup_script = data.template_file.startup_script.rendered
    private_ip     = local.private_ip
    domain         = var.domain
    proxy_user     = "sm://${var.project_id}/proxy_user"
    proxy_password = "sm://${var.project_id}/proxy_password"
    mysql_user     = "sm://${var.project_id}/mysql_user"
    mysql_password = "sm://${var.project_id}/mysql_password"

  }
}

data "template_file" "startup_script" {
  template = "${file("${path.module}/startup.sh.tpl")}"
  vars = {
    instance_name = local.instance_name
    config_path   = "/etc/traefik/test.json"
    cluster_cidr  = var.cluster_cidr
    traefik_token = var.traefik_token
  }
}

resource "google_compute_address" "instance-static-ip" {
  name = "traefik-container-vm"
}

resource "google_compute_instance" "vm" {
  project                   = var.project_id
  name                      = local.instance_name
  machine_type              = "f1-micro"
  zone                      = var.zone
  can_ip_forward            = true
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = module.gce-container.source_image
      size  = 20
    }
  }

  network_interface {
    subnetwork_project = var.subnetwork_project
    subnetwork         = var.subnetwork
    network_ip         = local.private_ip
    access_config {
      nat_ip = google_compute_address.instance-static-ip.address
    }
  }

  tags = ["traefik"]

  metadata = merge(
    {
      gce-container-declaration = module.gce-container.metadata_value
      google-logging-enabled    = "false"
      google-monitoring-enabled = "false"
      user-data                 = data.template_file.cloud-config.rendered
    },
    var.additional_metadata,
  )

  labels = {
    container-vm = module.gce-container.vm_container_label
  }

  service_account {
    email = var.client_email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/pubsub",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]
  }
  
  lifecycle {
    ignore_changes = [
      metadata
    ]
  }
}

resource "google_compute_firewall" "default" {
  name    = "traefik-ingress"
  network = var.network
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8181", "22"]
  }

  allow {
    protocol = "udp"
    ports    = ["9090"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["traefik"]
}

resource "google_compute_firewall" "coredns" {
  name    = "coredns"
  network = var.network
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["53"]
  }

  allow {
    protocol = "udp"
    ports    = ["53"]
  }

  source_ranges = var.subnet_ranges
  target_tags   = ["traefik", "coredns"]
}

resource "google_compute_firewall" "mysql" {
  name    = "mysql"
  network = var.network
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  source_ranges = var.subnet_ranges #["0.0.0.0/0"]
  target_tags   = ["traefik", "mysql"]
}

locals {
  credentials = {
    "proxy_user"     = { length = 8, special = false },
    "proxy_password" = { length = 16, special = false },
    "mysql_user"     = { length = 16, special = false },
    "mysql_password" = { length = 16, special = false }
  }
}

resource "random_password" "credentials" {
  for_each = local.credentials

  length  = each.value.length
  special = each.value.special
}

resource "google_secret_manager_secret" "secret" {

  for_each = local.credentials

  secret_id = each.key

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "secret-version" {
  for_each    = local.credentials

  secret      = google_secret_manager_secret.secret[each.key].id
  secret_data = random_password.credentials[each.key].result
}


resource "google_secret_manager_secret_iam_member" "member" {
  provider  = google-beta
  for_each  = local.credentials

  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.client_email}"
  secret_id = google_secret_manager_secret.secret[each.key].id
}
