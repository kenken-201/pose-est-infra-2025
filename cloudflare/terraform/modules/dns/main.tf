# ==============================================================================
# Cloudflare Zone Settings Module (Provider v5 対応)
# ==============================================================================
# このモジュールは Cloudflare ゾーンのセキュリティ設定と基本 DNS レコードを管理します。
#
# 含まれる設定:
# - SSL/TLS: Full (Strict) モード
# - Always Use HTTPS: 有効
# - Minimum TLS Version: 1.2
# - Browser Integrity Check: 有効
# - Security Level: Medium
# - DNSSEC: 有効化
# - Email Security: SPF/DMARC レコード (なりすまし防止)
#
# 注意: cloudflare_zone_setting リソースは destroy 時に Cloudflare API から
#       設定を削除できないため、lifecycle ブロックで明示的に管理しています。
# ==============================================================================

# -----------------------------------------------------------------------------
# Zone Security Settings
# -----------------------------------------------------------------------------
# 各設定を個別リソースとして定義 (Provider v5 の cloudflare_zone_setting)

resource "cloudflare_zone_setting" "ssl" {
  zone_id    = var.zone_id
  setting_id = "ssl"
  value      = "strict" # Full (Strict): オリジン証明書の検証を強制

  lifecycle {
    prevent_destroy = true # 誤操作による設定削除を防止
  }
}

resource "cloudflare_zone_setting" "always_use_https" {
  zone_id    = var.zone_id
  setting_id = "always_use_https"
  value      = "on" # HTTP → HTTPS 自動リダイレクト

  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_zone_setting" "min_tls_version" {
  zone_id    = var.zone_id
  setting_id = "min_tls_version"
  value      = "1.2" # TLS 1.0/1.1 を拒否

  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_zone_setting" "browser_check" {
  zone_id    = var.zone_id
  setting_id = "browser_check"
  value      = "on" # ブラウザ整合性チェック (Bot 対策)

  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_zone_setting" "security_level" {
  zone_id    = var.zone_id
  setting_id = "security_level"
  value      = "medium" # 標準的な保護レベル

  lifecycle {
    prevent_destroy = true
  }
}

# -----------------------------------------------------------------------------
# DNSSEC
# -----------------------------------------------------------------------------
# DNSSEC を有効化し、DNS スプーフィング攻撃から保護します。
# 完全に有効化するには、レジストラに DS レコードを登録する必要があります。

resource "cloudflare_zone_dnssec" "this" {
  zone_id = var.zone_id

  lifecycle {
    prevent_destroy = true
  }
}

# -----------------------------------------------------------------------------
# Email Security Records (No-Email Domain Protection)
# -----------------------------------------------------------------------------
# このドメインからメールを送信しないことを宣言し、フィッシングやなりすましを防ぎます。
# 参考: https://www.cloudflare.com/learning/dns/dns-records/protect-domains-without-email/

resource "cloudflare_dns_record" "spf" {
  zone_id = var.zone_id
  name    = "@"
  type    = "TXT"
  content = "v=spf1 -all" # Hard fail: 全ての送信元を拒否
  ttl     = 3600
  comment = "Email Security: SPF - No authorized senders"
}

resource "cloudflare_dns_record" "dmarc" {
  zone_id = var.zone_id
  name    = "_dmarc"
  type    = "TXT"
  content = "v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s;" # 厳格な拒否ポリシー
  ttl     = 3600
  comment = "Email Security: DMARC - Reject all unauthenticated mail"
}
