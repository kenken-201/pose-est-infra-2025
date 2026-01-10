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
