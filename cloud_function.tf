resource "google_storage_bucket_object" "server_toggle" {
  count = var.enable_cloud_func_management ? 1 : 0

  name   = "cloud_funcs/server_toggle.zip"
  bucket = google_storage_bucket.minecraft_pre_reqs[count.index].name
  source = local.cloud_func_code_zip_path
}

resource "google_project_iam_custom_role" "server_toggle" {
  count = var.enable_cloud_func_management ? 1 : 0

  role_id     = "${replace(var.project_name, "-", "_")}_toggler"
  title       = "MC Server Cloud Function Toggle"
  description = "IAM Role to allow invoking Cloud Functions and some Compute Engine APIs"

  permissions = [
    "cloudfunctions.functions.invoke",
    "compute.instances.get",
    "compute.instances.list",
    "compute.instances.start",
    "compute.instances.stop"
  ]
}

resource "google_cloudfunctions_function" "server_toggle" {
  count = var.enable_cloud_func_management ? length(local.cloud_function_data) : 0

  name        = local.cloud_function_data[count.index]["name"]
  description = local.cloud_function_data[count.index]["description"]
  runtime     = "python39"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.minecraft_pre_reqs[0].name
  source_archive_object = google_storage_bucket_object.server_toggle[0].name
  trigger_http          = true
  entry_point           = "http_post"

  # We interpolate the MODE here so that we create two Cloud Functions of identical
  # functions, aside on how they are invoked.
  environment_variables = merge(local.cloud_function_std_env_vars, { MODE = local.cloud_function_data[count.index]["mode"] })
}

resource "google_cloudfunctions_function_iam_member" "server_toggle" {
  count = var.enable_cloud_func_management ? length(local.cloud_function_data) : 0

  project        = google_cloudfunctions_function.server_toggle[count.index].project
  region         = google_cloudfunctions_function.server_toggle[count.index].region
  cloud_function = google_cloudfunctions_function.server_toggle[count.index].name

  role = google_project_iam_custom_role.server_toggle[0].name

  # We are ok with allowing anyone to invoke this; otherwise we would need to
  # manage a list of Google Account users to add to this
  # Could be a future topic of discussion
  member = "allUsers"
}