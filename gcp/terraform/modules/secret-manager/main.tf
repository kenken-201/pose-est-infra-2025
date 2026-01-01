/*
  Secret Manager モジュール main.tf
  -----------------------------------------------------------------------------
  Cloudflare R2 クレデンシャル用のシークレットリソースを作成します。
  実際の値は gcloud CLI 等で登録するため、ここでは「箱」のみを定義します。
  また、Cloud Run サービスアカウントへのアクセス権限を設定します。
*/

# -----------------------------------------------------------------------------
# シークレットリソース定義 (箱のみ)
# -----------------------------------------------------------------------------

# R2 Access Key ID
resource "google_secret_manager_secret" "r2_access_key_id" {
  secret_id = "r2-access-key-id-${var.environment}"
  project   = var.project_id

  replication {
    auto {} # コストとシンプルさのため自動レプリケーション
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
