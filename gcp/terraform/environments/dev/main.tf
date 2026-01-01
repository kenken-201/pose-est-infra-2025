/*
  Dev 環境メイン設定
  -----------------------------------------------------------------------------
  開発環境 (dev) 用のリソースを定義します。
  各モジュール (gcp-project, networking) を呼び出してインフラを構築します。
*/

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

# -----------------------------------------------------------------------------
# GCP プロジェクト基本設定 (API, 予算)
# -----------------------------------------------------------------------------
module "gcp_project" {
  source = "../../modules/gcp-project"

  project_id  = var.project_id
  environment = var.environment

  # billing_account_id はオプション（設定されなければ通知なし）
}

# -----------------------------------------------------------------------------
# ネットワーク基盤 (VPC, NAT)
# -----------------------------------------------------------------------------
module "networking" {
  source = "../../modules/networking"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment
  subnet_cidr = "10.0.0.0/24"

  depends_on = [module.gcp_project] # API 有効化後に実行
}

# -----------------------------------------------------------------------------
# IAM (サービスアカウント & 権限)
# -----------------------------------------------------------------------------
module "iam" {
  source = "../../modules/iam"

  project_id  = var.project_id
  environment = var.environment

  depends_on = [module.gcp_project] # IAM API 有効化後に実行
}

# -----------------------------------------------------------------------------
# Artifact Registry (コンテナレジストリ)
# -----------------------------------------------------------------------------
module "artifact_registry" {
  source = "../../modules/artifact-registry"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment

  # IAM モジュールの出力 (member 形式) を使用
  cloud_build_sa_member = module.iam.cloud_build_sa_member
  cloud_run_sa_member   = module.iam.cloud_run_sa_member

  # 開発環境ではタグの上書きを許可 (latest タグの更新など)
  immutable_tags = false

  depends_on = [
    module.gcp_project, # API 有効化後
    module.iam          # SA 作成後
  ]
}
