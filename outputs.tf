
output "kubernetes_endpoint" {
  description = "The cluster endpoint"
  sensitive   = true
  value       = module.gke.endpoint
}

output "ca_certificate" {
  description = "The cluster ca certificate (base64 encoded)"
  value       = module.gke.ca_certificate
}

output "service_account" {
  description = "The default service account used for running nodes."
  value       = module.gke.service_account
}

output "cluster_name" {
  description = "Cluster name"
  value       = module.gke.name
}

output "network_name" {
  description = "The name of the VPC being created"
  value       = module.gcp-network.network_name
}

output "subnet_name" {
  description = "The name of the subnet being created"
  value       = module.gcp-network.subnets_names
}

output "subnet_secondary_ranges" {
  description = "The secondary ranges associated with the subnet"
  value       = module.gcp-network.subnets_secondary_ranges
}

output "peering_name" {
  description = "The name of the peering between this cluster and the Google owned VPC."
  value       = module.gke.peering_name
}

output "kubeconfig" {
  description = "Convenience output for setting KUBECONFIG env"
  value       = "gcloud container clusters get-credentials ${module.gke.name} --zone=${module.gke.location}"
}

output "instance_name" {
  description = "The deployed instance name"
  value       = module.traefik.instance_name
}

output "vm_container_label" {
  description = "The instance label containing container configuration"
  value       = module.traefik.vm_container_label
}

output "container" {
  description = "The container metadata provided to the module"
  value       = module.traefik.container
}

output "volumes" {
  description = "The volume metadata provided to the module"
  value       = module.traefik.volumes
}

output "ipv4" {
  description = "The public IP address of the deployed instance"
  value       = module.traefik.ipv4
}

output "ssh-vm" {
  description = "Command to ssh into traefik instance"
  value       = module.traefik.ssh-vm
}

output "url" {
  description = "The Cloud Run url"
  value       = module.cloud-run.url
}

output "vault-url" {
  description = "The Vault Cloud Run url"
  value       = module.vault.app_url
}

output "annotate_sa" {
  description = "Annotate Service Account"
  value       = module.pomerium-workload-identity.annotate_sa
}

output "root_token_decrypt_command" {
  description = "Decrypt Command"
  value       = module.vault.root_token_decrypt_command
}
