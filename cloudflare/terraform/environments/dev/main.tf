/*
  Dev 環境メイン設定
  -----------------------------------------------------------------------------
  開発環境 (dev) 用の Cloudflare リソースを定義します。
  各モジュール (r2, dns, pages) を呼び出してインフラを構築します。
*/

terraform {
  required_version = ">= 1.14.3"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
}

# プロバイダー設定
provider "cloudflare" {
  # API トークンは CLOUDFLARE_API_TOKEN 環境変数経由で提供されます
}

# 共通設定のためのローカル値
locals {
  project_name = "pose-est"

  common_tags = {
    project     = local.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

# -----------------------------------------------------------------------------
# R2 バケットモジュール (動画保存用)
# -----------------------------------------------------------------------------
# 環境ごとの R2 バケットを作成します。
# バケット名は `pose-est-videos-<env>` の形式になります。

module "r2_bucket" {
  source = "../../modules/r2"

  account_id  = var.cloudflare_account_id
  bucket_name = "pose-est-videos-${var.environment}"
  location    = "apac"

  # 開発環境はすべてのオリジンを許可、本番環境は特定ドメインのみに制限可能
  # tfvars 経由で環境ごとに異なる値を注入します
  # pages_dev_target (プレビュー環境) が指定されていれば追加します
  cors_origins = concat(
    var.cors_origins,
    var.pages_dev_target != "" ? [var.pages_dev_target] : []
  )
}

# -----------------------------------------------------------------------------
# DNS / ゾーン設定モジュール
# -----------------------------------------------------------------------------
# ゾーンのセキュリティ設定 (SSL, DNSSEC) と基本レコードを管理します。

module "dns" {
  source = "../../modules/dns"

  zone_id            = var.cloudflare_zone_id
  domain_name        = var.domain_name
  additional_records = var.additional_records
}

# -----------------------------------------------------------------------------
# Cloudflare Pages モジュール (フロントエンドホスティング)
# -----------------------------------------------------------------------------
# Pages プロジェクトの設定 (ビルド、デプロイ、環境変数) を管理します。
# ※ GitHub 連携 (source) は手動設定 → import が必要です。

# module "pages" {
#   source = "../../modules/pages"
# 
#   account_id   = var.cloudflare_account_id
#   project_name = var.pages_project_name
# 
#   # ビルド設定
#   build_config = var.pages_build_config
#   node_version = var.node_version
# 
#   # デプロイメント設定 (環境変数)
#   # tfvars の設定に加えて、環境変数 (TF_VAR_api_target) から動的に値を注入
#   preview_vars = merge(
#     var.pages_preview_vars,
#     var.api_target != "" ? { VITE_API_URL = var.api_target } : {}
#   )
# 
#   production_vars = merge(
#     var.pages_production_vars,
#     var.api_target != "" ? { VITE_API_URL = var.api_target } : {}
#   )
# }
