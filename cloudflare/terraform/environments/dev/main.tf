/*
  Dev 環境メイン設定
  -----------------------------------------------------------------------------
  開発環境 (dev) 用の Cloudflare リソースを定義します。
  各モジュール (r2, dns) と Workers カスタムドメインを管理します。
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
  cors_origins = var.cors_origins
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
# Workers カスタムドメイン設定
# -----------------------------------------------------------------------------
# フロントエンド (Workers) 用の DNS レコードとルート設定
# ※ Workers 本体 (Script) はフロントエンドリポジトリ (wrangler) で管理

resource "cloudflare_workers_custom_domain" "frontend_dev" {
  account_id = var.cloudflare_account_id
  zone_id    = var.cloudflare_zone_id
  service    = "pose-est-frontend" # wrangler.jsonc の "name" と一致させる
  hostname   = "dev.kenken-pose-est.online"
}

# -----------------------------------------------------------------------------
# セキュリティモジュール (WAF)
# -----------------------------------------------------------------------------
# カスタムファイアウォールルールを適用します。
# Note: Managed WAF は Free プラン制限のため Dashboard で設定

module "security" {
  source = "../../modules/security"

  zone_id     = var.cloudflare_zone_id
  environment = var.environment
}
