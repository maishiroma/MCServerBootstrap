locals {
  unique_resource_name = "${var.project_name}-${random_string.unique.result}"

  zone_name     = "${var.region}-${var.zone_prefix}"
  subnet_name   = "${local.unique_resource_name}-sub"
  instance_name = "${local.unique_resource_name}-ins"

  mc_script_location = "${var.mc_home_folder}/scripts"
  mount_location     = "/dev/sdb"
  jar_name           = "server.jar"
  screen_ses         = "mc_server"

  screen_cmd = var.override_server_activate_cmd == "" ? "java -Xms${var.server_min_ram} -Xmx${var.server_max_ram} -jar ${var.mc_home_folder}/${local.jar_name} nogui" : var.override_server_activate_cmd

  cloud_func_code_zip_path = "${path.module}/server_toggle.zip"
  cloud_function_data = [
    {
      name        = "${var.project_name}_start",
      description = "Toggles the MC Server, ${var.project_name}, on"
      mode        = "start"
    },
    {
      name        = "${var.project_name}_stop",
      description = "Toggles the MC Server, ${var.project_name}, off"
      mode        = "stop"
    }
  ]

  cloud_function_std_env_vars = {
    PROJECT   = var.gcp_project_id
    INST_ZONE = local.zone_name
    INST_TAG  = var.project_name
  }

  common_labels = {
    project   = var.project_name
    terraform = "true"
    is_modded = var.is_modded
  }
}

resource "random_string" "unique" {
  length  = 5
  special = false
  upper   = false
}

data "archive_file" "cloud_func_code" {
  count = var.enable_cloud_func_management ? 1 : 0

  type        = "zip"
  source_dir  = "${path.module}/scripts/toggle_gcp_instance"
  output_path = local.cloud_func_code_zip_path
}

data "template_file" "bootstrap" {
  template = file("${path.module}/templates/bootstrap.tpl")

  vars = {
    mount_location          = local.mount_location
    is_modded               = var.is_modded
    jar_name                = local.jar_name
    screen_ses              = local.screen_ses
    screen_cmd              = local.screen_cmd
    mc_home_folder          = var.mc_home_folder
    mc_script_location      = local.mc_script_location
    mc_server_download_link = var.is_modded == false ? var.mc_server_download_link : var.mc_forge_server_download_link
    backup_bucket           = google_storage_bucket.minecraft.name
    ext_bucket              = var.is_modded == false ? "" : "${local.unique_resource_name}-ext-data"
    backup_cron             = var.backup_cron
    instance_name           = local.instance_name
    zone_name               = local.zone_name
    min_ram                 = var.server_min_ram
    max_ram                 = var.server_max_ram
    backup_key              = "backup-conf"
    restore_key             = "restore-conf"
    restart_key             = "restart-conf"
    stop_key                = "stop-conf"
    mod_refresh_key         = "mod-conf"
    mc_server_prop_key      = "mc-conf"
  }
}

data "template_file" "shutdown" {
  template = file("${path.module}/templates/shutdown.tpl")

  vars = {
    screen_ses         = local.screen_ses
    mc_script_location = local.mc_script_location
  }
}

data "template_file" "backup_script" {
  template = file("${path.module}/templates/backup.tpl")

  vars = {
    screen_ses     = local.screen_ses
    mc_home_folder = var.mc_home_folder
    backup_bucket  = google_storage_bucket.minecraft.name
    world_name     = var.server_world_name
  }
}

data "template_file" "restore_backup_script" {
  template = file("${path.module}/templates/restore_backup.tpl")

  vars = {
    screen_ses     = local.screen_ses
    screen_cmd     = local.screen_cmd
    mc_home_folder = var.mc_home_folder
    backup_bucket  = google_storage_bucket.minecraft.name
    world_name     = var.server_world_name
  }
}

data "template_file" "restart_script" {
  template = file("${path.module}/templates/restart.tpl")

  vars = {
    screen_ses     = local.screen_ses
    screen_cmd     = local.screen_cmd
    mc_home_folder = var.mc_home_folder
  }
}

data "template_file" "stop_script" {
  template = file("${path.module}/templates/stop.tpl")

  vars = {
    screen_ses     = local.screen_ses
    mc_home_folder = var.mc_home_folder
  }
}

data "template_file" "mod_refresh_script" {
  template = file("${path.module}/templates/mod_refresh.tpl")

  vars = {
    screen_ses     = local.screen_ses
    screen_cmd     = local.screen_cmd
    mc_home_folder = var.mc_home_folder
    ext_bucket     = var.is_modded == false ? "" : "${local.unique_resource_name}-ext-data"
  }
}

data "template_file" "mc_server_conf" {
  template = file(var.server_property_template)

  vars = {
    world_name = var.server_world_name
  }
}