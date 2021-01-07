variable "project_id" {
  description = "The project ID to deploy resources into"
}

variable "subnetwork_project" {
  description = "The project ID where the desired subnetwork is provisioned"
}

variable "subnetwork" {
  description = "The name of the subnetwork to deploy instances into"
}

variable "instance_name" {
  description = "The desired name to assign to the deployed instance"
  default     = "traefik-container-vm"
}

variable "zone" {
  description = "The GCP zone to deploy instances into"
  type        = string
}

variable "additional_metadata" {
  type        = map(string)
  description = "Additional metadata to attach to the instance"
  default     = {}
}

variable "client_email" {
  description = "Service account email address"
  type        = string
  default     = ""
}

variable "cos_image_name" {
  description = "The forced COS image to use instead of latest"
  default     = "cos-stable-85-13310-1041-38"
}

variable "cloud_init_custom_var" {
  description = "String passed in to the cloud-config template as custome variable."
  type        = string
  default     = ""
}

variable "vm_tags" {
  description = "Additional network tags for the instances."
  type        = list(string)
  default     = []
}

variable "ca_crt" {
  description = "Kubernetes ca.crt."
  type        = string
  default     = ""
}

variable "traefik_token" {
  description = "Kubernetes service account auth token for traefik."
  type        = string
  default     = ""
}

variable "endpoint" {
  description = "Cluster endpoint."
  type        = string
  default     = ""
}

variable "domain" {
  description = "Domain to create DNS server for"
  type        = string
  default     = "example.com"
}