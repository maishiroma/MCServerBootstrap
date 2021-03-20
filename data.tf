locals {
  zone_name = "${var.region}-${var.zone_prefix}"
}

data "template_file" "bootstrap" {
  template = file("${path.root}/bootstrap.sh")
}