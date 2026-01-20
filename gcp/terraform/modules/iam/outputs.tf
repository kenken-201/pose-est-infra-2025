/*
  IAM モジュール outputs.tf
  -----------------------------------------------------------------------------
  作成されたサービスアカウントの情報を出力します。
  他のモジュール（Cloud Run 等）で参照するために使用されます。
*/

output "cloud_run_sa_email" {
  description = "Cloud Run 実行用サービスアカウントのメールアドレス"
  value       = google_service_account.cloud_run.email
}

output "cloud_build_sa_email" {
  description = "Cloud Build 実行用サービスアカウントのメールアドレス"
  value       = google_service_account.cloud_build.email
}

output "cloud_run_sa_id" {
  description = "Cloud Run 実行用サービスアカウントのリソース名 (projects/-/serviceAccounts/...)"
  value       = google_service_account.cloud_run.name
}

output "cloud_build_sa_id" {
  description = "Cloud Build 実行用サービスアカウントのリソース名"
  value       = google_service_account.cloud_build.name
}

# -----------------------------------------------------------------------------
# 便利機能: IAM メンバー形式
# -----------------------------------------------------------------------------

output "cloud_run_sa_member" {
  description = "IAM ポリシーバインディングで使用可能な形式 (serviceAccount:<email>)"
  value       = "serviceAccount:${google_service_account.cloud_run.email}"
}

output "cloud_build_sa_member" {
  description = "IAM ポリシーバインディングで使用可能な形式 (serviceAccount:<email>)"
  value       = "serviceAccount:${google_service_account.cloud_build.email}"
}
