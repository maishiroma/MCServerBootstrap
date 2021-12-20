data "google_compute_subnetwork" "existing_subnet" {
  count = var.existing_subnetwork_name != "" ? 1 : 0

  name = var.existing_subnetwork_name
}

data "google_compute_network" "existing_network" {
  count = var.existing_subnetwork_name != "" ? 1 : 0

  name = basename(data.google_compute_subnetwork.existing_subnet[count.index].network)
}

resource "google_compute_network" "minecraft" {
  count = var.existing_subnetwork_name == "" ? 1 : 0

  name                    = "${local.unique_resource_name}-net"
  description             = "The VPC used to host the minecraft instance"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "minecraft" {
  count = var.existing_subnetwork_name == "" ? 1 : 0

  name          = local.subnet_name
  network       = google_compute_network.minecraft[count.index].id
  region        = var.region
  ip_cidr_range = "10.128.0.0/9"
}

resource "google_compute_firewall" "ingress_game" {
  count = var.existing_subnetwork_name == "" ? 1 : 0

  name        = "${local.unique_resource_name}-game"
  network     = google_compute_network.minecraft[count.index].id
  description = "Ingress traffic to instances for game trafffic"

  direction = "INGRESS"

  source_ranges = var.game_whitelist_ips

  allow {
    protocol = "tcp"
    ports    = ["25565"]
  }
}

resource "google_compute_firewall" "ingress_admin" {
  count = var.existing_subnetwork_name == "" ? 1 : 0

  name        = "${local.unique_resource_name}-ops"
  network     = google_compute_network.minecraft[count.index].id
  description = "Ingress traffic to instances for admin access"

  direction = "INGRESS"

  source_ranges = var.admin_whitelist_ips

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports = [
      "22"
    ]
  }
}

resource "google_compute_firewall" "ingress_game_extra_tcp" {
  count = length(var.extra_tcp_game_ports) > 0 ? 1 : 0

  name        = "${local.unique_resource_name}-game-extra"
  network     = var.existing_subnetwork_name == "" ? google_compute_network.minecraft[count.index].id : data.google_compute_network.existing_network[count.index].id
  description = "Additional ingress traffic to instances for game trafffic"

  direction = "INGRESS"

  source_ranges = var.game_whitelist_ips

  allow {
    protocol = "tcp"
    ports    = var.extra_tcp_game_ports
  }
}

resource "google_compute_firewall" "ingress_game_extra_udp" {
  count = length(var.extra_udp_game_ports) > 0 ? 1 : 0

  name        = "${local.unique_resource_name}-game-extra"
  network     = var.existing_subnetwork_name == "" ? google_compute_network.minecraft[count.index].id : data.google_compute_network.existing_network[count.index].id
  description = "Additional ingress traffic to instances for game trafffic"

  direction = "INGRESS"

  source_ranges = var.game_whitelist_ips

  allow {
    protocol = "udp"
    ports    = var.extra_udp_game_ports
  }
}

resource "google_compute_firewall" "egress" {
  count = var.existing_subnetwork_name == "" ? 1 : 0

  name        = "${local.unique_resource_name}-out"
  network     = google_compute_network.minecraft[count.index].id
  description = "egress traffic from instances"

  direction = "EGRESS"

  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
}