resource "google_compute_instance" "minecraft" {
  name         = var.project_name
  machine_type = var.machine_type
  zone         = local.zone_name

  boot_disk {
    initialize_params  {
      image = var.server_image
    }
  }

  attached_disk {
    source = google_compute_disk.minecraft.name
    mode = "READ_WRITE"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.minecraft.name

    access_config {
      network_tier = "STANDARD"
      nat_ip       = google_compute_address.minecraft.address
    }
  }

  metadata_startup_script = data.template_file.bootstrap.rendered

  metadata = {
    ssh-keys        = "${var.ssh_user}:${file(var.ssh_pub_key_file)}"
    shutdown-script = data.template_file.shutdown.rendered
  }

  service_account {
    scopes = [
      "compute-ro",
      "storage-rw"
    ]
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    google_storage_bucket.minecraft
  ]
}

resource "google_compute_disk" "minecraft" {
  name        = "${var.project_name}-gamedata"
  description = "External disk to store Minecraft files"
  zone        = local.zone_name
  type        = "pd-ssd"
  size        = var.disk_size
}