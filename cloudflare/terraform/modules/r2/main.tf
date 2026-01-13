resource "cloudflare_r2_bucket" "this" {
  account_id = var.account_id
  name       = var.bucket_name
  location   = var.location
}

/*
  ライフサイクルポリシー設定
  -----------------------------------------------------------------------------
  コスト最適化のため、指定日数後にオブジェクトを自動削除します。
  retention_days 変数で保持期間を制御します。
*/
resource "cloudflare_r2_bucket_lifecycle" "retention" {
  account_id  = var.account_id
  bucket_name = cloudflare_r2_bucket.this.name

  rules = [
    {
      id      = "${var.retention_days}-day-retention"
      enabled = true

      conditions = {
        prefix = "" # 全てのオブジェクトに適用
      }

      delete_objects_transition = {
        condition = {
          type    = "Age"
          max_age = var.retention_days * 86400 # 日数を秒に変換
        }
      }

      # 不完全なマルチパートアップロードを7日後に削除 (コスト/整合性対策)
      abort_multipart_uploads_transition = {
        condition = {
          type    = "Age"
          max_age = 7 * 86400 # 7日
        }
      }

      storage_class_transitions = []
    }
  ]
}

# CORS 設定 (フロントエンドからのアクセス用)
resource "cloudflare_r2_bucket_cors" "this" {
  account_id  = var.account_id
  bucket_name = cloudflare_r2_bucket.this.name

  rules = [
    {
      allowed = {
        methods = ["GET", "PUT", "HEAD", "POST"]
        origins = var.cors_origins
        headers = ["*"]
      }
      expose_headers  = ["ETag"]
      max_age_seconds = 3600
    }
  ]
}
