/*
  IAM モジュール main.tf
  -----------------------------------------------------------------------------
  サービスアカウントの作成と IAM ロールの割り当てを行います。
  最小権限の原則 (Least Privilege) に基づき、各サービスに必要な権限のみを慎重に付与します。
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
# アプリケーション（バックエンド API）が実行時に使用する ID です。
resource "google_service_account" "cloud_run" {
  account_id   = "cloud-run-sa-${var.environment}"
  display_name = "Cloud Run Service Account (${var.environment})"
  description  = "Cloud Run サービス実行用 identity。Secret Manager へのアクセスやログ書き込みに使用します。"
  project      = var.project_id
}

# Cloud Build 実行用サービスアカウント
# CI/CD パイプライン（ビルド・デプロイ）を実行する ID です。
resource "google_service_account" "cloud_build" {
  account_id   = "cloud-build-sa-${var.environment}"
  display_name = "Cloud Build Service Account (${var.environment})"
  description  = "Cloud Build 実行用 identity。コンテナビルド、Artifact Registry へのプッシュ、Cloud Run へのデプロイに使用します。"
  project      = var.project_id
}

# -----------------------------------------------------------------------------
# IAM ロール割り当て: Cloud Run サービスアカウント (Runtime)
# -----------------------------------------------------------------------------
resource "google_project_iam_member" "cloud_run_roles" {
  for_each = toset([
    # R2 クレデンシャル等を Secret Manager から取得するために必要
    # Note: セキュリティ向上のため、将来的には特定の Secret リソースのみへのアクセスに制限することを推奨
    "roles/secretmanager.secretAccessor",

    # アプリケーションログを出力するために必要
    "roles/logging.logWriter",

    # 分散トレーシング (Cloud Trace) 情報を送信するために必要
    "roles/cloudtrace.agent"
  ])

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

# -----------------------------------------------------------------------------
# IAM ロール割り当て: Cloud Build サービスアカウント (CI/CD)
# -----------------------------------------------------------------------------
resource "google_project_iam_member" "cloud_build_roles" {
  for_each = toset([
    # ビルドした Docker イメージを Artifact Registry にプッシュするために必要
    "roles/artifactregistry.writer",

    # Cloud Run サービスをデプロイ・更新するために必要
    "roles/run.developer",

    # Cloud Build のログを出力するために必要
    "roles/logging.logWriter"
  ])

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.cloud_build.email}"
}

# -----------------------------------------------------------------------------
# セキュリティ強化: Service Account Impersonation (なりすまし) の制限
# -----------------------------------------------------------------------------
# Cloud Build が Cloud Run サービスをデプロイする際、Cloud Run サービスアカウントを割り当てる必要があります。
# これを許可するために `roles/iam.serviceAccountUser` が必要ですが、
# プロジェクトレベルで付与すると「すべての」サービスアカウントを使用できてしまい危険です。
# そのため、Cloud Build SA が 「Cloud Run SA のみ」 を使用できるように制限します。

resource "google_service_account_iam_member" "cloud_build_impersonates_cloud_run" {
  service_account_id = google_service_account.cloud_run.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.cloud_build.email}"
}
