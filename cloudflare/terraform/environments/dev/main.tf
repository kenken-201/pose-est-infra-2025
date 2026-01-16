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
# 【背景・目的】
# Cloud Run をカスタムドメイン (api-dev.kenken-pose-est.online) で公開する際、
# Cloud Run 側は本来のドメイン (*.run.app) の Host ヘッダーを要求します (デフォルト仕様)。
#
# 通常、Cloudflare Pro プラン以上であれば "Origin Rules" 機能で Host ヘッダーを書き換えられますが、
# Free プランではその機能が制限されています。
#
# そのため、Cloudflare Workers をリバースプロキシとして間に挟み、
# Worker 内でプログラム的に Host ヘッダーを `*.run.app` に書き換えてから
# Cloud Run へリクエストを転送する構成を採用しています。
# -----------------------------------------------------------------------------

resource "cloudflare_workers_script" "api_proxy_dev" {
  account_id  = var.cloudflare_account_id
  script_name = "pose-est-api-proxy-dev"
  
  # Secret Binding (認証トークン)
  bindings = [{
    name = "BACKEND_ACCESS_TOKEN"
    type = "secret_text"
    text = var.backend_access_token
  }]

  # Worker Script 定義 (Inline)
  # 1. すべてのリクエスト ('fetch' event) を捕捉
  # 2. handleRequest 関数でリクエスト内容 (URL, Header) を加工
  # 3. Cloud Run へ転送
  content     = <<EOT
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  // 元のリクエストURLをパース
  const url = new URL(request.url);
  
  // 転送先 (Backend Cloud Run) のホスト名を環境変数から構築
  // var.cloud_run_url (https://...run.app) からプロトコルとパスを除去してホスト名のみ抽出
  const targetHostname = "${replace(replace(var.cloud_run_url, "https://", ""), "/", "")}";
  
  // リクエストURLのホスト名を Cloud Run のものに書き換え
  url.hostname = targetHostname;
  
  // 新しいリクエストオブジェクトを作成 (元のリクエストを複製)
  // ここで Host ヘッダーを明示的に Cloud Run のホスト名に上書きします
  // ※ これを行わないと Cloud Run は 404 Not Found を返します
  const newRequest = new Request(url.toString(), request);
  newRequest.headers.set("Host", targetHostname);

  // 認証トークンをヘッダーに付与
  // BACKEND_ACCESS_TOKEN は secret_text_binding で注入されたグローバル変数
  newRequest.headers.set("X-CF-Access-Token", BACKEND_ACCESS_TOKEN);
  
  // 書き換えたリクエストを Cloud Run へ送信 (Fetch)
  return fetch(newRequest);
}
EOT
}

# Worker を特定のカスタムドメインに紐付ける設定
# これにより https://api-dev.kenken-pose-est.online へのアクセスが
# 上記の Worker スクリプトによって処理されるようになります。
resource "cloudflare_workers_custom_domain" "api_proxy_dev" {
  account_id = var.cloudflare_account_id
  zone_id    = var.cloudflare_zone_id
  service    = "pose-est-api-proxy-dev" # 上記の script_name と一致させる必要があります
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

