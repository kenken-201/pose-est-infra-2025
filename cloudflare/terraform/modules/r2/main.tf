resource "cloudflare_r2_bucket" "this" {
  account_id = var.account_id
  name       = var.bucket_name
  location   = var.location
}

/*
  ライフサイクルポリシー設定
  -----------------------------------------------------------------------------
  コスト最適化のため、7日間の有効期限ポリシーを設定します。
*/
resource "cloudflare_r2_bucket_lifecycle_rule" "retention" {
  account_id  = var.account_id
  bucket_name = cloudflare_r2_bucket.this.name

  rule {
    id     = "7-day-retention"
    status = "enabled"

    expiration {
      days = 7
    }
  }
}

# CORS 設定 (フロントエンドからのアクセス用)
resource "cloudflare_r2_bucket_cors" "this" {
  account_id  = var.account_id
  bucket_name = cloudflare_r2_bucket.this.name

  rule {
    allowed_methods = ["GET", "PUT", "HEAD", "POST"]
    allowed_origins = var.cors_origins
    allowed_headers = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}
