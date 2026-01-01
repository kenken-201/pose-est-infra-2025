/*
  メイン Terraform 設定
  -----------------------------------------------------------------------------
  このファイルはすべての Cloudflare インフラストラクチャモジュールを統合管理します。
  モジュールは以降のフェーズで追加されます:
    - Phase 2: R2 ストレージ
    - Phase 3: DNS
    - Phase 4: Cloudflare Pages
    - Phase 5: セキュリティ (WAF, レート制限)
*/

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

/*
  R2 バケットモジュール (動画保存用)
  -----------------------------------------------------------------------------
  環境ごとの R2 バケットを作成します。
  バケット名は `pose-est-videos-<env>` の形式になります。
*/
module "r2_bucket" {
  source = "./modules/r2"

  account_id  = var.cloudflare_account_id
  bucket_name = "pose-est-videos-${var.environment}"
  location    = "apac"

  # 開発環境はすべてのオリジンを許可、本番環境は特定ドメインのみに制限可能
  # tfvars 経由で環境ごとに異なる値を注入します
  cors_origins = var.cors_origins
}

/*
  DNS / ゾーン設定モジュール
  -----------------------------------------------------------------------------
  ゾーンのセキュリティ設定 (SSL, DNSSEC) と基本レコードを管理します。
*/
module "dns" {
  source = "./modules/dns"

  zone_id     = var.cloudflare_zone_id
  domain_name = var.domain_name
}
