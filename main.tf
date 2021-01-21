data "google_project" "project" {
  project_id = var.project_id
}

module "gcp-network" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 2.5"
  project_id   = var.project_id
  network_name = var.network

  subnets = [
    {
      subnet_name           = var.subnetwork
      subnet_ip             = "10.0.0.0/17"
      subnet_region         = var.region
      subnet_private_access = "true"
    },
  ]

  secondary_ranges = {
    "${var.subnetwork}" = [
      {
        range_name    = var.ip_range_pods_name
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = var.ip_range_services_name
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}

module "gke" {
  source     = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  project_id = var.project_id
  name       = var.cluster_name
  regional   = false
  region     = var.region
  zones      = slice(var.zones, 0, 1)

  network                    = module.gcp-network.network_name
  subnetwork                 = module.gcp-network.subnets_names[0]
  ip_range_pods              = var.ip_range_pods_name
  ip_range_services          = var.ip_range_services_name
  create_service_account     = true
  enable_private_endpoint    = false
  enable_private_nodes       = true
  master_ipv4_cidr_block     = "172.16.0.0/28"
  http_load_balancing        = false
  remove_default_node_pool   = true
  skip_provisioners          = true
  maintenance_start_time     = "22:00"
  network_policy             = false
  monitoring_service         = "none"
  logging_service            = "none"
  add_cluster_firewall_rules = true
  firewall_inbound_ports     = ["8443", "9443", "15017"]
  node_pools = [
    {
      name         = "ingress-pool"
      machine_type = "e2-micro"
      disk_size_gb = 10
      autoscaling  = false
      node_count   = 2
      image_type   = "COS_CONTAINERD"
      auto_upgrade = true
      preemptible  = true
    },
    {
      name               = "web-pool"
      machine_type       = "e2-micro"
      disk_size_gb       = 10
      autoscaling        = false
      initial_node_count = 2
      node_count         = 2
      image_type         = "COS_CONTAINERD"
      auto_upgrade       = true
      preemptible        = true
    },
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/service.management",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/trace.append",
    ]

  }

  node_pools_taints = {
    all = []
    ingress-pool = [
      /*
      {
        key    = "ingress-pool"
        value  = true
        effect = "NO_EXECUTE"
      },
      */
    ]
  }

  node_pools_tags = {
    ingress-pool = [
      "ingress-pool"
    ]
    web-pool = [
      "web-pool"
    ]
  }

  master_authorized_networks = [
    {
      cidr_block   = module.gcp-network.subnets_ips[0] #OR #lookup(module.gcp-network.subnets, "${var.region}/${var.subnetwork}").ip_cidr_range
      display_name = "VPC"
    },
    {
      display_name = "Anyone"
      cidr_block   = "0.0.0.0/0"
    },
  ]
  /*
  stub_domains   =   {
    "${var.domain}" = ["10.0.0.67"]
  }
  
  database_encryption = [{
    state    = "ENCRYPTED"
    key_name = module.kms.keys.gke-secrets-key
  }]
  */

}

data "google_client_config" "default" {}

module "gke_auth" {
  source = "terraform-google-modules/kubernetes-engine/google//modules/auth"

  project_id   = var.project_id
  location     = module.gke.location
  cluster_name = module.gke.name
}

module "traefik-sa" {
  source = "./modules/traefik-sa"

  project_id             = var.project_id
  host                   = module.gke_auth.host
  cluster_ca_certificate = module.gke_auth.cluster_ca_certificate
  token                  = module.gke_auth.token
  client_email           = module.gke.service_account
  domain                 = var.domain
  run_post_install       = var.run_post_install
}

module "traefik" {
  source = "./modules/traefik-vm"

  project_id         = var.project_id
  zone               = module.gke.location
  subnetwork         = module.gcp-network.subnets_names[0]
  client_email       = module.gke.service_account
  endpoint           = module.gke.endpoint
  traefik_token      = module.traefik-sa.traefik_token
  ca_crt             = module.traefik-sa.ca_crt
  subnetwork_project = var.project_id
  network            = module.gcp-network.network_self_link
  domain             = var.domain
  subnet_ranges      = concat(module.gcp-network.subnets_ips, [for s in module.gcp-network.subnets_secondary_ranges[0] : s.ip_cidr_range])

}


module "dns" {
  source = "./modules/dns"

  project_id             = var.project_id
  host                   = module.gke_auth.host
  cluster_ca_certificate = module.gke_auth.cluster_ca_certificate
  token                  = module.gke_auth.token
  traefik_ip             = module.traefik.ipv4
  traefik_ip_private     = module.traefik.ipv4_private
  dns_auth               = var.dns_auth
  domain                 = var.domain
  domain_filter          = var.domain_filter
  check_interval         = "2m"

}


module "cert" {
  source = "./modules/cert"

  project_id             = var.project_id
  zone                   = module.gke.location
  host                   = module.gke_auth.host
  cluster_ca_certificate = module.gke_auth.cluster_ca_certificate
  token                  = module.gke_auth.token
  domain                 = var.domain
  run_post_install       = var.run_post_install
}


module "custom-nat" {
  source = "./modules/custom-nat"

  project_id   = var.project_id
  zone         = module.gke.location
  host         = module.gke.endpoint
  network      = module.gcp-network.network_name
  subnetwork   = module.gcp-network.subnets_names[0]
  hop_instance = module.traefik.instance_name
  region       = var.region
}

module "cloud-run" {
  source             = "./modules/cloud-run"
  project_id         = var.project_id
  zone               = module.gke.location
  region             = var.region
  gke_serviceaccount = module.gke.service_account
  pomerium_sa        = module.pomerium-workload-identity.gcp_service_account_email
  proxy_server       = module.traefik.proxy_server
  domain             = var.domain
  run_post_install   = var.run_post_install
}

module "pomerium" {
  source = "./modules/pomerium-app"

  project_id             = var.project_id
  zone                   = module.gke.location
  host                   = module.gke_auth.host
  cluster_ca_certificate = module.gke_auth.cluster_ca_certificate
  token                  = module.gke_auth.token
  cloudrun_url           = module.cloud-run.url
  domain                 = var.domain
  vault_cloudrun_url     = module.vault.app_url
  oidc_config            = var.oidc_config
  email                  = var.email
}

module "vault" {
  source = "./modules/vault-cloud-run"

  name = "vault"

  project                = var.project_id
  location               = var.region
  vault_ui               = true
  vault_image            = "mirror.gcr.io/library/vault"
  bucket_force_destroy   = true
  run_post_install       = var.run_post_install
}


module "vault-sa" {
  source = "./modules/vault-sa"

  host                   = module.gke_auth.host
  cluster_ca_certificate = module.gke_auth.cluster_ca_certificate
  token                  = module.gke_auth.token
  vault_cloudrun_url     = module.vault.app_url
}

/*
module "vault-config" {
  source = "./modules/vault-cloud-run/vault-config"

  vault_address              = module.vault.app_url
  root_token_decrypt_command = module.vault.root_token_decrypt_command
  host                       = module.gke_auth.host
  cluster_ca_certificate     = module.gke_auth.cluster_ca_certificate
  domain                     = var.domain
  project                    = var.project_id
  location                   = var.region
  token                      = module.vault-sa.token
  ca_crt                     = module.vault-sa.ca_crt
  oidc_config                = var.oidc_config
  email                      = var.email
}
*/

module "pomerium-workload-identity" {
  source              = "./modules/workload-identity"
  use_existing_k8s_sa = true
  name                = "pomerium-authorize"
  namespace           = "default"
  project_id          = var.project_id
  roles               = ["roles/run.invoker"]
  cluster_name        = var.cluster_name
  location            = module.gke.location
}

module "external-dns-workload-identity" {
  source              = "./modules/workload-identity"
  use_existing_k8s_sa = true
  name                = "external-dns"
  namespace           = "default"
  project_id          = var.project_id
  roles               = ["roles/dns.admin"]
  cluster_name        = var.cluster_name
  location            = module.gke.location
}
  
module "cert-manager-workload-identity" {
  source              = "./modules/workload-identity"
  use_existing_k8s_sa = true
  name                = "cert-manager"
  namespace           = "cert-manager"
  project_id          = var.project_id
  roles               = ["roles/dns.admin"]
  cluster_name        = var.cluster_name
  location            = module.gke.location
}


module "test-workload-identity" {
  source = "./modules/test-workload-identity"

  host                   = module.gke_auth.host
  cluster_ca_certificate = module.gke_auth.cluster_ca_certificate
  token                  = module.gke_auth.token
  ksa                    = module.pomerium-workload-identity.k8s_service_account_name
  run_post_install       = var.run_post_install
}
