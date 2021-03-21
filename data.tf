locals {
  zone_name = "${var.region}-${var.zone_prefix}"
}

data "template_file" "bootstrap" {
  template = file("${path.root}/templates/bootstrap.tpl")

  vars = {
    mc_home_folder          = var.mc_home_folder
    mc_server_download_link = var.mc_server_download_link
    server_min_ram          = var.server_min_ram
    server_max_ram          = var.server_max_ram
    backup_bucket           = google_storage_bucket.minecraft.name
  }
}

data "template_file" "shutdown" {
  template = file("${path.root}/templates/shutdown.tpl")
}