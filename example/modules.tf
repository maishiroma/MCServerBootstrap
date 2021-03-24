# Bare minimum module usage
module "mc_bootstrap" {
  # For using this outside of this repo, make sure to specify the source in a git URL
  source = "../"

  # General Variables
  region           = var.region
  creds_json       = var.creds_json
  ssh_pub_key_file = var.ssh_pub_key_file

  # Network Variables
  game_whitelist_ips  = var.game_whitelist_ips
  admin_whitelist_ips = var.admin_whitelist_ips

  # Minecraft Variables
  server_property_template = var.server_property_template
}

# An example of how one would make multiple MC servers, using the subnetwork output of the first module.
#module "mc_bootstrap_2" {
#  # For using this outside of this repo, make sure to specify the source in a git URL
#  source = "../"
#
#  # General Variables
#  region           = var.region
#  creds_json       = var.creds_json
#  ssh_pub_key_file = var.ssh_pub_key_file
#
#  # Network Variables
#  game_whitelist_ips  = var.game_whitelist_ips
#  admin_whitelist_ips = var.admin_whitelist_ips
#
#  # Minecraft Variables
#  server_property_template = var.server_property_template
#  existing_subnetwork_name = module.mc_bootstrap.created_subnetwork[0]
#}