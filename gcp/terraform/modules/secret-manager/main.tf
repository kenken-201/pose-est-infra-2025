/*
  Secret Manager モジュール main.tf
  -----------------------------------------------------------------------------
  Cloudflare R2 クレデンシャル用のシークレットリソースを作成します。
  実際の値は gcloud CLI 等で登録するため、ここでは「箱」のみを定義します。
  また、Cloud Run サービスアカウントへのアクセス権限を設定します。
*/

# -----------------------------------------------------------------------------
# シークレットリソース定義
# -----------------------------------------------------------------------------

# R2 Access Key ID
resource "google_secret_manager_secret" "r2_access_key_id" {
  secret_id = "r2-access-key-id-${var.environment}"
  project   = var.project_id

  replication {
    # 自動レプリケーション (Google 管理キーで暗号化)
    auto {}
  }
}

# R2 Secret Access Key
resource "google_secret_manager_secret" "r2_secret_access_key" {
  secret_id = "r2-secret-access-key-${var.environment}"
  project   = var.project_id

  replication {
    auto {}
  }
}

# R2 Secret Access Key Version (値の登録)
resource "google_secret_manager_secret_version" "r2_secret_access_key_version" {
  secret      = google_secret_manager_secret.r2_secret_access_key.id
  secret_data = var.r2_secret_access_key
}

# Backend Access Token (Cloudflare <-> Cloud Run 認証用)
resource "google_secret_manager_secret" "backend_access_token" {
  secret_id = "backend-access-token-${var.environment}"
  project   = var.project_id

  replication {
    auto {}
  }
}

# Backend Access Token Version (値の登録)
resource "google_secret_manager_secret_version" "backend_access_token_version" {
  secret      = google_secret_manager_secret.backend_access_token.id
  secret_data = var.backend_access_token
}

# -----------------------------------------------------------------------------
# IAM 権限設定 (リソースレベル: 最小権限)
# -----------------------------------------------------------------------------

# Cloud Run SA に Access Key ID へのアクセス権を付与
resource "google_secret_manager_secret_iam_member" "r2_access_key_id_accessor" {
  secret_id = google_secret_manager_secret.r2_access_key_id.id
  role      = "roles/secretmanager.secretAccessor"
  member    = var.cloud_run_sa_member
}

# Cloud Run SA に Secret Access Key へのアクセス権を付与
resource "google_secret_manager_secret_iam_member" "r2_secret_access_key_accessor" {
  secret_id = google_secret_manager_secret.r2_secret_access_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = var.cloud_run_sa_member
}

# Cloud Run SA に Backend Access Token へのアクセス権を付与
resource "google_secret_manager_secret_iam_member" "backend_access_token_accessor" {
  secret_id = google_secret_manager_secret.backend_access_token.id
  role      = "roles/secretmanager.secretAccessor"
  member    = var.cloud_run_sa_member
}
