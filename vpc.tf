resource "google_compute_network" "minecraft" {
  name                    = "${var.project_name}-network"
  description             = "The VPC used to host the minecraft instance"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "minecraft" {
  name          = "${var.project_name}-subnetwork"
  network       = google_compute_network.minecraft.id
  region        = var.region
  ip_cidr_range = "10.128.0.0/9"
}

resource "google_compute_firewall" "ingress_game" {
  name        = "${var.project_name}-ingress-game"
  network     = google_compute_network.minecraft.id
  description = "Ingress traffic to instances for game trafffic"

  direction = "INGRESS"

  source_ranges = var.game_whitelist_ips

  allow {
    protocol = "tcp"
    ports = [
      "25565"
    ]
  }
}

resource "google_compute_firewall" "ingress_admin" {
  name        = "${var.project_name}-ingress-admin"
  network     = google_compute_network.minecraft.id
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

resource "google_compute_firewall" "egress" {
  name        = "${var.project_name}-egress"
  network     = google_compute_network.minecraft.id
  description = "egress traffic from instances"

  direction = "EGRESS"

  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
}

resource "google_compute_address" "minecraft" {
  name        = "${var.project_name}-ext"
  description = "The static IP used to access this instance extenrally"

  address_type = "EXTERNAL"
  network_tier = "STANDARD"
}