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

# -----------------------------------------------------------------------------
# Secret Manager (R2 クレデンシャル管理)
# -----------------------------------------------------------------------------
module "secret_manager" {
  source = "../../modules/secret-manager"

  project_id  = var.project_id
  environment = var.environment

  # IAM モジュールの出力 (member 形式) を使用
  cloud_run_sa_member = module.iam.cloud_run_sa_member

  depends_on = [
    module.gcp_project,
    module.iam
  ]
}

# -----------------------------------------------------------------------------
# Cloud Run (バックエンド API)
# -----------------------------------------------------------------------------
module "cloud_run" {
  source = "../../modules/cloud-run"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment

  # コンテナイメージ (Artifact Registry)
  image_url = "${module.artifact_registry.repository_url}/pose-est-backend:latest"

  # サービスアカウント
  service_account_email = module.iam.cloud_run_sa_email

  # R2 クレデンシャル (Secret Manager Secret ID を渡す)
  # modules/secret-manager の output を使用
  r2_access_key_id_secret_id     = module.secret_manager.r2_access_key_id_secret_id
  r2_secret_access_key_secret_id = module.secret_manager.r2_secret_access_key_secret_id

  # R2 環境設定 (変数から取得)
  r2_account_id  = var.r2_account_id
  r2_bucket_name = "pose-est-media-${var.environment}"

  # 公開アクセス設定 (Dev環境は許可)
  allow_unauthenticated = true

  # スケーリング設定 (Dev用 Low Cost)
  min_instance_count      = 0
  max_instance_count      = 2
  max_request_concurrency = 1
  cpu_idle                = true
  startup_cpu_boost       = true

  # リソース制限 (Dev用: TensorFlow 向けに増強)
  cpu_limit    = "2"
  memory_limit = "2Gi"

  # 管理用ラベル
  labels = {
    "component" = "api"
  }

  depends_on = [
    module.secret_manager,
    module.artifact_registry,
    module.iam
  ]
}
