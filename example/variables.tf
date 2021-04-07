# These variables (besides the ones with preset defaults) are the minimum parameters one needs to pass
# into this module for it to work properly. 


variable "creds_json" {}

variable "region" {
  default = "us-west2"
}

variable "ssh_pub_key_file" {}

variable "game_whitelist_ips" {}

variable "admin_whitelist_ips" {}

variable "server_property_template" {
  default = "./custom_templates/server_properties.tpl"
}

variable "backup_length" {}