/*
  Dev 環境 outputs.tf
  -----------------------------------------------------------------------------
  Terraform apply 後に参照可能な出力値を定義します。
*/

output "service_url" {
  description = "Cloud Run サービスの URL"
  value       = module.cloud_run.service_url
}

output "service_name" {
  description = "Cloud Run サービス名"
  value       = module.cloud_run.service_name
}

output "artifact_registry_url" {
  description = "Artifact Registry リポジトリ URL"
  value       = module.artifact_registry.repository_url
}
