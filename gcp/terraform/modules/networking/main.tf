/*
  ネットワーキングモジュール
  -----------------------------------------------------------------------------
  VPC ネットワーク、サブネット、Cloud Router、および Cloud NAT を構築します。
  Cloud Run などのリソースがプライベートネットワーク内で安全に通信するための基盤を提供します。
*/

terraform {
  required_version = ">= 1.14.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

# -----------------------------------------------------------------------------
# VPC ネットワーク
# -----------------------------------------------------------------------------
resource "google_compute_network" "vpc" {
  name                    = "pose-est-vpc-${var.environment}"
  project                 = var.project_id
  auto_create_subnetworks = false # カスタムサブネットモードを使用
}

# -----------------------------------------------------------------------------
# サブネット
# -----------------------------------------------------------------------------
resource "google_compute_subnetwork" "subnet" {
  name          = "pose-est-subnet-${var.environment}"
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.subnet_cidr

  # Private Google Access を有効化 (外部 IP なしで Google API にアクセス可能)
  private_ip_google_access = true
}

# -----------------------------------------------------------------------------
# Cloud Router (Cloud NAT 用)
# -----------------------------------------------------------------------------
resource "google_compute_router" "router" {
  name    = "pose-est-router-${var.environment}"
  project = var.project_id
  region  = var.region
  network = google_compute_network.vpc.id
}

# -----------------------------------------------------------------------------
# Cloud NAT 用静的 IP (Static IP)
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
  name    = "pose-est-nat-${var.environment}"
  project = var.project_id
  region  = var.region
  router  = google_compute_router.router.name

  # 静的 IP を割り当て (IP ホワイトリスト対応のため)
  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = [google_compute_address.nat.self_link]

  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
