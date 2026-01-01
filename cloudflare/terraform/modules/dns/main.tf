# Zone Settings (using cloudflare_zone_setting resource for individual settings in v5)

resource "cloudflare_zone_setting" "ssl" {
  zone_id    = var.zone_id
  setting_id = "ssl"
  value      = "strict"
}

resource "cloudflare_zone_setting" "always_use_https" {
  zone_id    = var.zone_id
  setting_id = "always_use_https"
  value      = "on"
}

resource "cloudflare_zone_setting" "min_tls_version" {
  zone_id    = var.zone_id
  setting_id = "min_tls_version"
  value      = "1.2"
}

resource "cloudflare_zone_setting" "browser_check" {
  zone_id    = var.zone_id
  setting_id = "browser_check"
  value      = "on"
}

resource "cloudflare_zone_setting" "security_level" {
  zone_id    = var.zone_id
  setting_id = "security_level"
  value      = "medium"
}

resource "cloudflare_zone_dnssec" "this" {
  zone_id = var.zone_id
}

# -----------------------------------------------------------------------------
# Email Security Records (No-Email Domain Protection)
# -----------------------------------------------------------------------------
# このドメインからメールを送信しないことを宣言し、なりすましを防ぎます。

resource "cloudflare_dns_record" "spf" {
  zone_id = var.zone_id
  name    = "@"
  type    = "TXT"
  content = "v=spf1 -all" # Hard fail: No IPs are authorized to send email
  ttl     = 3600
  comment = "Email Security: SPF for no-email domain"
}

resource "cloudflare_dns_record" "dmarc" {
  zone_id = var.zone_id
  name    = "_dmarc"
  type    = "TXT"
  content = "v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s;" # Reject all unauthenticated mail
  ttl     = 3600
  comment = "Email Security: DMARC reject policy"
}
