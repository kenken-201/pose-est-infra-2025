/*
  Cloud Run モジュール main.tf
  -----------------------------------------------------------------------------
  Cloud Run v2 サービスを作成します。
  コンテナ設定、Secret Manager からの環境変数注入、リソース制限設定を含みます。
*/

resource "google_cloud_run_v2_service" "service" {
  name     = "pose-est-backend-${var.environment}"
  location = var.region
  project  = var.project_id
  ingress  = var.ingress

  template {
    # サービスアカウント
    service_account = var.service_account_email

    containers {
      image = var.image_url

      ports {
        container_port = 8080 # FastAPI デフォルト
      }

      # -------------------------------------------------------------------------
      # 環境変数 (Secret Manager 連携)
      # -------------------------------------------------------------------------
      env {
        name  = "ENV"
        value = var.environment
      }

      # R2 クレデンシャル (Secret Manager から注入)
      env {
        name = "AWS_ACCESS_KEY_ID"
        value_source {
          secret_key_ref {
            secret  = var.r2_access_key_id_secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "AWS_SECRET_ACCESS_KEY"
        value_source {
          secret_key_ref {
            secret  = var.r2_secret_access_key_secret_id
            version = "latest"
          }
        }
      }

      # R2 環境設定 (プレーンテキスト)
      env {
        name  = "R2_ACCOUNT_ID"
        value = var.r2_account_id
      }
      env {
        name  = "R2_BUCKET_NAME"
        value = var.r2_bucket_name
      }
      env {
        name  = "R2_ENDPOINT_URL"
        value = "https://${var.r2_account_id}.r2.cloudflarestorage.com"
      }
      env {
        name  = "R2_SIGN_EXPIRATION"
        value = "3600"
      }

      # Python/FastAPI 設定
      env {
        name  = "PYTHONUNBUFFERED"
        value = "1"
      }

      # -------------------------------------------------------------------------
      # リソース制限 (Dev 環境用: 最小構成)
      # -------------------------------------------------------------------------
      resources {
        limits = {
          cpu    = var.cpu_limit
          memory = var.memory_limit
        }
        cpu_idle = var.cpu_idle
      }

      # -------------------------------------------------------------------------
      # ヘルスチェック (Startup Probe)
      # -------------------------------------------------------------------------
      startup_probe {
        http_get {
          path = "/health"
          port = 8080
        }
        initial_delay_seconds = 5
        timeout_seconds       = 3
        failure_threshold     = 3
        period_seconds        = 10
      }
    }

    # スケーリング設定
    scaling {
      min_instance_count = var.min_instance_count
      max_instance_count = var.max_instance_count
    }

    max_instance_request_concurrency = var.max_request_concurrency
  }
}

# -----------------------------------------------------------------------------
# IAM 設定 (公開アクセス)
# -----------------------------------------------------------------------------
resource "google_cloud_run_service_iam_member" "public_access" {
  count    = var.allow_unauthenticated ? 1 : 0
  location = google_cloud_run_v2_service.service.location
  project  = google_cloud_run_v2_service.service.project
  service  = google_cloud_run_v2_service.service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
