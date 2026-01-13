/*
  Production 環境メイン設定
  -----------------------------------------------------------------------------
  本番環境 (production) 用の Cloudflare リソースを定義します。
  - R2 Bucket: pose-est-videos-production
  - DNS: kenken-pose-est.online (Root) -> Worker
  - WWW Redirect: www -> Root
  - Security: WAF, Rate Limiting
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

provider "cloudflare" {
  # API Token via CLOUDFLARE_API_TOKEN env var
}

# -----------------------------------------------------------------------------
# R2 バケットモジュール
# -----------------------------------------------------------------------------
module "r2_bucket" {
  source = "../../modules/r2"

  account_id   = var.cloudflare_account_id
  bucket_name  = "pose-est-videos-${var.environment}"
  location     = "apac"
  cors_origins = var.cors_origins
}

# -----------------------------------------------------------------------------
# DNS / ゾーン設定モジュール
# -----------------------------------------------------------------------------
module "dns" {
  source = "../../modules/dns"

  zone_id            = var.cloudflare_zone_id
  domain_name        = var.domain_name
  additional_records = var.additional_records
}

# -----------------------------------------------------------------------------
# Workers カスタムドメイン設定 (Root Domain)
# -----------------------------------------------------------------------------
resource "cloudflare_workers_custom_domain" "frontend_prod" {
  account_id = var.cloudflare_account_id
  zone_id    = var.cloudflare_zone_id
  service    = "pose-est-frontend" # wrangler.toml [env.production] name と一致が必要
  hostname   = "kenken-pose-est.online"
}

# -----------------------------------------------------------------------------
# WWW リダイレクト設定 (Task 24-2)
# -----------------------------------------------------------------------------
# 1. WWW CNAME Record
# 1. WWW CNAME Record (Provider v5: cloudflare_dns_record)
resource "cloudflare_dns_record" "www" {
  zone_id = var.cloudflare_zone_id
  name    = "www"
  content = "kenken-pose-est.online"
  type    = "CNAME"
  proxied = true
  ttl     = 1 # Auto
  comment = "Redirect to Root"
}

resource "cloudflare_ruleset" "www_redirect" {
  zone_id     = var.cloudflare_zone_id
  name        = "WWW Redirect to Root"
  description = "Redirect www to root domain"
  kind        = "zone"
  phase       = "http_request_dynamic_redirect"

  rules = [
    {
      action = "redirect"
      action_parameters = {
        from_value = {
          status_code = 301
          target_url = {
            expression = "concat(\"https://kenken-pose-est.online\", http.request.uri.path)"
          }
          preserve_query_string = true
        }
      }
      expression  = "(http.host eq \"www.kenken-pose-est.online\")"
      description = "Redirect www requests"
      enabled     = true
    }
  ]
}

# -----------------------------------------------------------------------------
# セキュリティモジュール (WAF)
# -----------------------------------------------------------------------------
module "security" {
  source = "../../modules/security"

  zone_id     = var.cloudflare_zone_id
  environment = var.environment
}

# -----------------------------------------------------------------------------
# 監視設定モジュール
# -----------------------------------------------------------------------------
module "monitoring" {
  source = "../../modules/monitoring"

  account_id = var.cloudflare_account_id
  zone_id    = var.cloudflare_zone_id
}
