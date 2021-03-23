output "server_ip_address" {
  description = "The public IP address used to access this instance"
  value       = google_compute_address.minecraft.address
}

output "created_subnetwork" {
  description = "The name of the created subnetwork that was provisioned in this module. Can be used to provision more servers in the same network if desired"
  value       = google_compute_subnetwork.minecraft.*.name
}