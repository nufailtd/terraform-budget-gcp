output "instance_name" {
  description = "The deployed instance name"
  value       = google_compute_instance.vm.name
}

output "vm_container_label" {
  description = "The instance label containing container configuration"
  value       = module.gce-container.vm_container_label
}

output "container" {
  description = "The container metadata provided to the module"
  value       = module.gce-container.container
}

output "volumes" {
  description = "The volume metadata provided to the module"
  value       = module.gce-container.volumes
}

output "ipv4" {
  description = "The public IP address of the deployed instance"
  value       = google_compute_instance.vm.network_interface.0.access_config.0.nat_ip
}

output "ipv4_private" {
  description = "The public IP address of the deployed instance"
  value       = google_compute_instance.vm.network_interface.0.network_ip
}

output "ssh-vm" {
  description = "Command to ssh into traefik instance"
  value       = "gcloud compute ssh ${google_compute_instance.vm.name} --zone=${google_compute_instance.vm.zone}"
}

output "proxy_server" {
  description = "Proxy Server in the format HOST:PORT"
  value       = "${google_compute_instance.vm.network_interface.0.access_config.0.nat_ip}:8181"
}

