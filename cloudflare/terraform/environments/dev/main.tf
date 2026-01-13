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
# Workaround: Worker Proxy for Host Override (Free Plan Support)
# -----------------------------------------------------------------------------
# Cloud Run はカスタムドメインの Host ヘッダーを 404 で拒否するため、
# 本来は Origin Rules (Pro Plan) で Host Header Rewrite が必要です。
# Free Plan で実現するため、Worker をリバースプロキシとして使用します。

resource "cloudflare_workers_script" "api_proxy_dev" {
  account_id  = var.cloudflare_account_id
  script_name = "pose-est-api-proxy-dev"
  content     = <<EOT
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  const url = new URL(request.url);
  const targetHostname = "${replace(replace(var.cloud_run_url, "https://", ""), "/", "")}";
  
  // Create new URL
  url.hostname = targetHostname;
  
  // Create new request with overridden Host header
  const newRequest = new Request(url.toString(), request);
  newRequest.headers.set("Host", targetHostname);
  
  return fetch(newRequest);
}
EOT
}

resource "cloudflare_workers_custom_domain" "api_proxy_dev" {
  account_id = var.cloudflare_account_id
  zone_id    = var.cloudflare_zone_id
  service    = "pose-est-api-proxy-dev" # Must match script_name
  hostname   = "api-dev.kenken-pose-est.online"
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

# -----------------------------------------------------------------------------
# 監視設定モジュール
# -----------------------------------------------------------------------------
# アナリティクスと監視設定を管理します (Free Plan 制限あり)
module "monitoring" {
  source = "../../modules/monitoring"

  account_id = var.cloudflare_account_id
  zone_id    = var.cloudflare_zone_id
}
