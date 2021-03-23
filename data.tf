locals {
  zone_name          = "${var.region}-${var.zone_prefix}"
  mc_script_location = "${var.mc_home_folder}/scripts"
  jar_name           = "server.jar"
  screen_ses         = "mc_server"
  screen_cmd         = "java -Xms${var.server_min_ram} -Xmx${var.server_max_ram} -jar ${var.mc_home_folder}/${local.jar_name} nogui"
}

data "template_file" "bootstrap" {
  template = file("${path.root}/templates/bootstrap.tpl")

  vars = {
    jar_name                = local.jar_name
    screen_ses              = local.screen_ses
    screen_cmd              = local.screen_cmd
    mc_home_folder          = var.mc_home_folder
    mc_script_location      = local.mc_script_location
    mc_server_download_link = var.mc_server_download_link
    backup_bucket           = google_storage_bucket.minecraft.name
    instance_name           = var.project_name
    zone_name               = local.zone_name
    backup_key              = "backup-conf"
    restore_key             = "restore-conf"
    restart_key             = "restart-conf"
    mc_server_prop_key      = "mc-conf"
  }
}

data "template_file" "shutdown" {
  template = file("${path.root}/templates/shutdown.tpl")
}

data "template_file" "backup_script" {
  template = file("${path.root}/templates/backup.tpl")

  vars = {
    screen_ses     = local.screen_ses
    mc_home_folder = var.mc_home_folder
    backup_bucket  = google_storage_bucket.minecraft.name
  }
}

data "template_file" "restore_backup_script" {
  template = file("${path.root}/templates/restore_backup.tpl")

  vars = {
    jar_name       = local.jar_name
    screen_ses     = local.screen_ses
    screen_cmd     = local.screen_cmd
    mc_home_folder = var.mc_home_folder
    backup_bucket  = google_storage_bucket.minecraft.name
  }
}

data "template_file" "restart_script" {
  template = file("${path.root}/templates/restart.tpl")

  vars = {
    jar_name       = local.jar_name
    screen_ses     = local.screen_ses
    screen_cmd     = local.screen_cmd
    mc_home_folder = var.mc_home_folder
    backup_bucket  = google_storage_bucket.minecraft.name
  }
}

data "template_file" "mc_server_conf" {
  template = file("${path.root}/templates/server_properties.tpl")
}