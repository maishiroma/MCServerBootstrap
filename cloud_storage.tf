resource "google_storage_bucket" "minecraft" {
  name          = "${local.unique_resource_name}-backup"
  location      = "US"
  storage_class = "STANDARD"

  lifecycle_rule {
    condition {
      age = var.backup_length
    }
    action {
      type = "Delete"
    }
  }

  force_destroy = true

  labels = local.common_labels
}

resource "google_storage_bucket" "minecraft_pre_reqs" {
  count = var.is_modded == true ? 1 : 0

  name          = "${local.unique_resource_name}-ext-data"
  location      = "US"
  storage_class = "STANDARD"

  force_destroy = true

  labels = local.common_labels
}