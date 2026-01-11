terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
}

# -----------------------------------------------------------------------------
# Custom Firewall Rules (カスタムファイアウォールルール)
# -----------------------------------------------------------------------------
# Free プランで使用可能なカスタムルールを定義します。
# Managed WAF (OWASP 等) は Free では Terraform 非対応のため Dashboard で設定してください。
#
# Reference:
# - https://developers.cloudflare.com/waf/custom-rules/
# - https://developers.cloudflare.com/ruleset-engine/rules-language/operators/

# -----------------------------------------------------------------------------
# Custom Firewall Rules
# -----------------------------------------------------------------------------
# カスタムルールを定義します (Task 13-3 で詳細化)

resource "cloudflare_ruleset" "zone_level_custom_firewall" {
  zone_id     = var.zone_id
  name        = "Custom Firewall Rules"
  description = "Custom firewall rules for ${var.environment} environment"
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  rules = [
    # 1. 脅威スコアに基づくブロック (共通)
    {
      action      = "block"
      expression  = "(cf.threat_score gt 40)"
      description = "Block high threat score requests (>40)"
      enabled     = true
    },
    # 2. API エンドポイントへの攻撃的なアクセスをブロック
    {
      action      = "block"
      expression  = "(http.request.uri.path contains \"/api/\" and cf.threat_score gt 20)"
      description = "Block suspicious access to API (>20)"
      enabled     = true
    },
    # 3. 日本国外からのアクセスに対する Managed Challenge (Bot 対策・DDoS 緩和)
    # 開発段階では誤検知を防ぐため無効化するか、慎重に設定
    {
      action      = "managed_challenge"
      expression  = "(ip.geoip.country ne \"JP\" and not cf.client.bot)"
      description = "Challenge non-JP requests (except known bots)"
      enabled     = false # 初期状態は無効化 (必要に応じて有効化)
    }
  ]
}

# -----------------------------------------------------------------------------
# Rate Limiting Rules (レート制限)
# -----------------------------------------------------------------------------
# Free プランは 1 つのルールのみ作成可能です。
# API エンドポイント全体を保護する汎用的なルールを設定します。
#
# Reference: 
# - https://developers.cloudflare.com/waf/rate-limiting-rules/
# - Free Plan Limits: Period=10s, Action=Block/Legacy Captcha only, Count=per-colo

resource "cloudflare_ruleset" "zone_level_rate_limit" {
  zone_id     = var.zone_id
  name        = "Rate Limiting Rules"
  description = "Rate limiting for API protection"
  kind        = "zone"
  phase       = "http_ratelimit"

  rules = [
    {
      action = "block" # Free plan: managed_challenge is NOT supported
      ratelimit = {
        characteristics     = ["ip.src", "cf.colo.id"] # Free plan requires per-colo counting
        period              = 10  # 10秒 (Free plan limit)
        requests_per_period = 20  # 10秒あたり20リクエスト (~120 req/min)
        mitigation_timeout  = 10  # 制限時間 10秒 (Free plan limit)
      }
      expression  = "(http.request.uri.path contains \"/api/\")"
      description = "Rate limit API requests (20 req/10s per IP)"
      enabled     = true
    }
  ]
}

# -----------------------------------------------------------------------------
# Security Headers (Transform Rules)
# -----------------------------------------------------------------------------
# Defense in Depth: インフラ層でセキュリティヘッダーを強制付与します。
# アプリケーション側での設定漏れや、Cloudflare エラーページ等も含めて保護します。

resource "cloudflare_ruleset" "zone_level_security_headers" {
  zone_id     = var.zone_id
  name        = "Security Headers"
  description = "Set baseline security headers for all responses"
  kind        = "zone"
  phase       = "http_response_headers_transform"

  rules = [
    {
      action = "rewrite"
      action_parameters = {
        headers = {
          # HSTS: 1年間の強制HTTPS + サブドメイン + Preload推奨
          "Strict-Transport-Security" = { operation = "set", value = "max-age=63072000; includeSubDomains; preload" }
          # MIME Sniffing 防止
          "X-Content-Type-Options"    = { operation = "set", value = "nosniff" }
          # Clickjacking 防止 (SameOrigin)
          "X-Frame-Options"           = { operation = "set", value = "DENY" }
          # Referrer Policy
          "Referrer-Policy"           = { operation = "set", value = "strict-origin-when-cross-origin" }
        }
      }
      expression  = "true" # 全てのレスポンスに適用
      description = "Set Security Headers"
      enabled     = true
    }
  ]
}
