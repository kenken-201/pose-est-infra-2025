/*
  Secret Manager モジュール outputs.tf
  -----------------------------------------------------------------------------
  シークレットの参照に必要な情報を出力します。
*/

output "r2_access_key_id_name" {
  description = "R2 Access Key ID シークレットのリソース名 (projects/.../secrets/...)"
  value       = google_secret_manager_secret.r2_access_key_id.name
}

output "r2_access_key_id_secret_id" {
  description = "R2 Access Key ID シークレット ID (Cloud Run 環境変数への参照用)"
  value       = google_secret_manager_secret.r2_access_key_id.secret_id
}

output "r2_secret_access_key_name" {
  description = "R2 Secret Access Key シークレットのリソース名 (projects/.../secrets/...)"
  value       = google_secret_manager_secret.r2_secret_access_key.name
}

output "r2_secret_access_key_secret_id" {
  description = "R2 Secret Access Key の Secret ID"
  value       = google_secret_manager_secret.r2_secret_access_key.secret_id
}

output "backend_access_token_secret_id" {
  description = "Backend Access Token の Secret ID"
  value       = google_secret_manager_secret.backend_access_token.secret_id
}
