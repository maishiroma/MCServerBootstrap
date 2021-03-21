resource "google_compute_instance_template" "minecraft" {
  name_prefix          = var.project_name
  description          = "This template is used to spin up Minecraft servers"
  instance_description = "A Minecraft Server"
  machine_type         = var.machine_type

  disk {
    boot         = true
    source_image = var.server_image
  }

  disk {
    boot         = false
    disk_name    = "mcdata"
    disk_type    = "pd-ssd"
    disk_size_gb = var.disk_size
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

resource "google_compute_instance_group_manager" "minecraft" {
  name        = "${var.project_name}-group"
  description = "Manager to micromanage this instance"
  zone        = local.zone_name

  base_instance_name = "mc-serv"
  version {
    instance_template = google_compute_instance_template.minecraft.id
  }

  target_pools = [google_compute_target_pool.minecraft.id]

  wait_for_instances = true
}

resource "google_compute_autoscaler" "minecraft" {
  name   = "${var.project_name}-as"
  zone   = local.zone_name
  target = google_compute_instance_group_manager.minecraft.id

  autoscaling_policy {
    max_replicas = 1
    min_replicas = 1
  }
}

resource "google_compute_target_pool" "minecraft" {
  name = "${var.project_name}-pool"
}