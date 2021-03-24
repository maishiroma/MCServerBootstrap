locals {
  unique_resource_name = "${var.project_name}-${random_string.unique.result}"

  zone_name     = "${var.region}-${var.zone_prefix}"
  subnet_name   = "${local.unique_resource_name}-sub"
  instance_name = "${local.unique_resource_name}-ins"

  mc_script_location = "${var.mc_home_folder}/scripts"
  jar_name           = "server.jar"
  screen_ses         = "mc_server"
  screen_cmd         = "java -Xms${var.server_min_ram} -Xmx${var.server_max_ram} -jar ${var.mc_home_folder}/${local.jar_name} nogui"

  common_labels = {
    project   = var.project_name
    terraform = "true"
  }
}

resource "random_string" "unique" {
  length  = 5
  special = false
  upper   = false
}

data "template_file" "bootstrap" {
  template = file("${path.module}/templates/bootstrap.tpl")

  vars = {
    jar_name                = local.jar_name
    screen_ses              = local.screen_ses
    screen_cmd              = local.screen_cmd
    mc_home_folder          = var.mc_home_folder
    mc_script_location      = local.mc_script_location
    mc_server_download_link = var.mc_server_download_link
    backup_bucket           = google_storage_bucket.minecraft.name
    backup_cron             = var.backup_cron
    instance_name           = local.instance_name
    zone_name               = local.zone_name
    backup_key              = "backup-conf"
    restore_key             = "restore-conf"
    restart_key             = "restart-conf"
    mc_server_prop_key      = "mc-conf"
  }
}

data "template_file" "shutdown" {
  template = file("${path.module}/templates/shutdown.tpl")

  vars = {
    screen_ses = local.screen_ses
  }
}

data "template_file" "backup_script" {
  template = file("${path.module}/templates/backup.tpl")

  vars = {
    screen_ses     = local.screen_ses
    mc_home_folder = var.mc_home_folder
    backup_bucket  = google_storage_bucket.minecraft.name
  }
}

data "template_file" "restore_backup_script" {
  template = file("${path.module}/templates/restore_backup.tpl")

  vars = {
    jar_name       = local.jar_name
    screen_ses     = local.screen_ses
    screen_cmd     = local.screen_cmd
    mc_home_folder = var.mc_home_folder
    backup_bucket  = google_storage_bucket.minecraft.name
  }
}

data "template_file" "restart_script" {
  template = file("${path.module}/templates/restart.tpl")

  vars = {
    jar_name       = local.jar_name
    screen_ses     = local.screen_ses
    screen_cmd     = local.screen_cmd
    mc_home_folder = var.mc_home_folder
    backup_bucket  = google_storage_bucket.minecraft.name
  }
}

data "template_file" "mc_server_conf" {
  template = file(var.server_property_template)
}