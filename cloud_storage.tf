resource "google_storage_bucket" "minecraft" {
  name          = "${var.project_name}-backup"
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
}