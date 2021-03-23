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