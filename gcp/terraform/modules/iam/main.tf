/*
  IAM モジュール main.tf
  -----------------------------------------------------------------------------
  サービスアカウントの作成と IAM ロールの割り当てを行います。
  最小権限の原則に基づき、各サービスに必要な権限のみを付与します。
*/

terraform {
  required_version = ">= 1.14.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

# -----------------------------------------------------------------------------
# サービスアカウント作成
# -----------------------------------------------------------------------------

# Cloud Run 実行用サービスアカウント
resource "google_service_account" "cloud_run" {
  account_id   = "cloud-run-sa-${var.environment}"
  display_name = "Cloud Run Service Account (${var.environment})"
  description  = "Cloud Run サービス実行用 (Secret Manager アクセス、ロギング等)"
  project      = var.project_id
}

# Cloud Build 実行用サービスアカウント
resource "google_service_account" "cloud_build" {
  account_id   = "cloud-build-sa-${var.environment}"
  display_name = "Cloud Build Service Account (${var.environment})"
  description  = "Cloud Build ビルド・デプロイ用 (Artifact Registry 書き込み、Cloud Run デプロイ等)"
  project      = var.project_id
}

# -----------------------------------------------------------------------------
# IAM ロール割り当て: Cloud Run サービスアカウント
# -----------------------------------------------------------------------------
resource "google_project_iam_member" "cloud_run_roles" {
  for_each = toset([
    "roles/secretmanager.secretAccessor", # Secret Manager アクセス (R2 クレデンシャル取得)
    "roles/logging.logWriter",            # Cloud Logging への書き込み
    "roles/cloudtrace.agent"              # Cloud Trace へのトレース送信
  ])

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

# -----------------------------------------------------------------------------
# IAM ロール割り当て: Cloud Build サービスアカウント
# -----------------------------------------------------------------------------
resource "google_project_iam_member" "cloud_build_roles" {
  for_each = toset([
    "roles/artifactregistry.writer", # Artifact Registry へのイメージプッシュ
    "roles/run.developer",           # Cloud Run へのデプロイ
    "roles/iam.serviceAccountUser",  # Cloud Run へのサービスアカウント割り当て権限
    "roles/logging.logWriter"        # Cloud Logging への書き込み
  ])

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.cloud_build.email}"
}
