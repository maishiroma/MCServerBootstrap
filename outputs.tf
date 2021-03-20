output "ip_address" {
  description = "The public IP address used to access this instance"
  value       = google_compute_address.minecraft.address
}