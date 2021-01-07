variable "project_id" {
  description = "The project ID to host the cluster in"
}

variable "cluster_name" {
  description = "The name for the GKE cluster"
  default     = "gke-on-vpc-cluster"
}

variable "region" {
  description = "The region to host the cluster in"
}

variable "zones" {
  type        = list(string)
  description = "The zone to host the cluster in (required if is a zonal cluster)"
}

variable "network" {
  description = "The VPC network created to host the cluster in"
  default     = "gke-network"
}

variable "subnetwork" {
  description = "The subnetwork created to host the cluster in"
  default     = "gke-subnet"
}

variable "ip_range_pods_name" {
  description = "The secondary ip range to use for pods"
  default     = "ip-range-pods"
}

variable "ip_range_services_name" {
  description = "The secondary ip range to use for services"
  default     = "ip-range-scv"
}

variable domain {
  description = "Domain to create with external-dns"
  default     = ""
}

variable domain_filter {
  description = "Domain filter for external-dns"
  default     = ""
}

variable email {
  description = "Your email used to login to Google Cloud Platform"
  default     = ""
}

variable "dns_auth" {
  type        = list(map(string))
  description = "DNS auth variables including the provider matching helm chart variables"
  default     = []
}

variable "oidc_config" {
  type        = list(map(string))
  description = "OIDC Configuration for protecting private resources. Used by Pomerium IAP & Vault."
  default     = []
}

variable run_post_install {
  default     = false
  description = "Whether to apply components that require existing resources"
}
