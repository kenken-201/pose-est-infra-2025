terraform {
  required_version = ">= 1.14.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

module "gcp_project" {
  source = "../../modules/gcp-project"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment
  
  # billing_account_id はオプション（設定されなければ予算アラートは作成されない）
}

module "networking" {
  source = "../../modules/networking"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment
  subnet_cidr = "10.0.0.0/24"
  
  depends_on = [module.gcp_project] # API有効化が終わってから作成
}
