terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

# -----------------------------------------------------------------------------
# VPC Network
# -----------------------------------------------------------------------------
resource "google_compute_network" "vpc" {
  name                    = "pose-est-vpc-${var.environment}"
  project                 = var.project_id
  auto_create_subnetworks = false
}

# -----------------------------------------------------------------------------
# Subnet
# -----------------------------------------------------------------------------
resource "google_compute_subnetwork" "subnet" {
  name          = "pose-est-subnet-${var.environment}"
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.subnet_cidr

  private_ip_google_access = true
}

# -----------------------------------------------------------------------------
# Cloud Router (for Cloud NAT)
# -----------------------------------------------------------------------------
resource "google_compute_router" "router" {
  name    = "pose-est-router-${var.environment}"
  project = var.project_id
  region  = var.region
  network = google_compute_network.vpc.id
}

# -----------------------------------------------------------------------------
# Cloud NAT Static IP
# -----------------------------------------------------------------------------
resource "google_compute_address" "nat" {
  name    = "pose-est-nat-ip-${var.environment}"
  project = var.project_id
  region  = var.region
}

# -----------------------------------------------------------------------------
# Cloud NAT
# -----------------------------------------------------------------------------
resource "google_compute_router_nat" "nat" {
  name                               = "pose-est-nat-${var.environment}"
  project                            = var.project_id
  region                             = var.region
  router                             = google_compute_router.router.name
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.nat.self_link]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
