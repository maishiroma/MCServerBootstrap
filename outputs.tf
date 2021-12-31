output "server_ip_address" {
  description = "The ephimeral public IP address used to access this instance."
  value       = google_compute_instance.minecraft.network_interface[0].access_config[0].nat_ip
}

output "created_subnetwork" {
  description = "The name of the created subnetwork that was provisioned in this module. Can be used to provision more servers in the same network if desired"
  value       = google_compute_subnetwork.minecraft.*.name
}

output "ext_bucket_name" {
  description = "The name of the Cloud Storage Bucket used to hold any persistent MC data."
  value       = google_storage_bucket.minecraft_pre_reqs.*.name
}

output "cloud_funcs_http_triggers" {
  description = "The URLs that correspond to the Cloud Functions, if created"
  value       = google_cloudfunctions_function.server_toggle.*.https_trigger_url
}