#### General Variables

variable "creds_json" {
  description = "The absolute path to the credential file to auth to GCP. This needs to be associated with the GCP project that is being used"
  type        = string
}

variable "region" {
  description = "The region used to place these resources. Defaults to us-west1"
  type        = string
  default     = "us-west2"
}

variable "zone_prefix" {
  description = "The zone prefix used for deployments. Defaults to 'a'."
  type        = string
  default     = "a"
}

variable "project_name" {
  description = "The name of the project. Not to be confused with the project name in GCP; this is moreso a terraform project name."
  type        = string
  default     = "mc-server-bootstrap"
}

#### Server Variables

variable "machine_type" {
  description = "The type of machine to spin up. If the instance is struggling, it might be worthwhile to use stronger machines."
  type        = string
  default     = "n1-standard-2"
}

variable "server_image" {
  description = "The boot image used on the server. Defaults to `ubuntu-1804-bionic-v20191211`"
  type        = string
  default     = "ubuntu-1804-bionic-v20191211"
}

variable "ssh_user" {
  description = "The name of the user to allow to SSH into the instance"
  type        = string
  default     = "iamall"
}

variable "ssh_pub_key_file" {
  description = "The SSH public key file to use to connect to the instance as the user specified in ssh_user"
  type        = string
}

#### Disk Variables

variable "disk_size" {
  description = "How big do you want the SSD disk to be? Defaults to 50 GB"
  type        = string
  default     = "50"
}

#### Network Variables

variable "existing_subnetwork_name" {
  description = "An existing subnetwork to leverage placing the instances. Assumes that the firewalls in the subnetwork are already configured."
  type        = string
  default     = ""
}

variable "game_whitelist_ips" {
  description = "The IPs used to connect to the Minecraft server itself through the MC client. If existing_subnetwork_name is specified, this will be ignored."
  type        = list(string)
}

variable "admin_whitelist_ips" {
  description = "The IPs to allow for SSH and ping access, generally reseved for operational work/troubleshooting. If existing_subnetwork_name is specified, this will be ignored."
  type        = list(string)
}

#### Backup Variables

variable "backup_length" {
  description = "How many days will a backup last in the bucket?"
  type        = number
  default     = 5
}

variable "backup_cron" {
  description = "How often will the backups run on the instance? This must be written in cron syntax. Defaults to once a week on Sats at 3AM"
  type        = string
  default     = "0 3 * * 6"
}

#### Bootstrap Variables

variable "mc_home_folder" {
  description = "The location of the Minecraft server files on the instance"
  type        = string
  default     = "/home/minecraft"
}

variable "mc_server_download_link" {
  description = "The direct download link to download the server jar. Defaults to a link with 1.16.5."
  type        = string
  default     = "https://launcher.mojang.com/v1/objects/35139deedbd5182953cf1caa23835da59ca3d7cd/server.jar"
}

variable "mc_forge_server_download_link" {
  description = "The direct download link to MC forge for modding support. Defaults to version 1.16.5."
  type        = string
  default     = "https://files.minecraftforge.net/maven/net/minecraftforge/forge/1.16.5-36.1.0/forge-1.16.5-36.1.0-installer.jar"
}

variable "server_min_ram" {
  description = "The minimum amount of RAM to allocate to the server process"
  type        = string
  default     = "1G"
}

variable "server_max_ram" {
  description = "The maximum amount of RAM to allocate to the server process"
  type        = string
  default     = "7G"
}

variable "server_property_template" {
  description = "The file path used to parse the server property file for the MC server. Defaults to the standard one in the module"
  type        = string
  default     = "./templates/server_properties.tpl"
}

variable "is_modded" {
  description = "Is this Minecraft server modded? Defaults to false."
  type        = bool
  default     = false
}