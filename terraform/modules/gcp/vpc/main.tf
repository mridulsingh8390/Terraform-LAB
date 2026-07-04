################################################################################
# GCP VPC Module
# Creates: VPC network, GKE subnet with secondary ranges for pods/services,
# Cloud Router + NAT for private node egress
################################################################################

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  project                 = var.project_id
}

# ── GKE subnet with secondary ranges for pod and service IPs ──────────────────

resource "google_compute_subnetwork" "gke" {
  name          = "${var.prefix}-snet-gke"
  ip_cidr_range = var.gke_subnet_cidr
  network       = google_compute_network.vpc.id
  region        = var.region
  project       = var.project_id

  private_ip_google_access = true # allows private nodes to reach Google APIs

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }
}

# ── Firewall rules ────────────────────────────────────────────────────────────

# Allow internal VPC traffic (node-to-node, Filestore NFS, health checks)
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.prefix}-fw-allow-internal"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = [var.gke_subnet_cidr, var.pods_cidr]
}

# Allow GKE master to reach nodes (required for webhook controllers, etc.)
resource "google_compute_firewall" "allow_master_to_nodes" {
  name    = "${var.prefix}-fw-master-to-nodes"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["443", "8443", "10250"]
  }

  source_ranges = [var.master_ipv4_cidr]
}

# ── Cloud Router + NAT — gives private nodes outbound internet access ──────────

resource "google_compute_router" "router" {
  name    = "${var.prefix}-router"
  network = google_compute_network.vpc.name
  region  = var.region
  project = var.project_id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.prefix}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  project                            = var.project_id
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
