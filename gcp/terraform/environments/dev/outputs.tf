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
