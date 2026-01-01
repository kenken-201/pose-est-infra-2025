/*
  Cloud Run モジュール outputs.tf
  -----------------------------------------------------------------------------
  Cloud Run サービスの出力値定義
*/

output "service_name" {
  description = "Cloud Run サービス名"
  value       = google_cloud_run_v2_service.service.name
}

output "service_url" {
  description = "Cloud Run サービスの URL"
  value       = google_cloud_run_v2_service.service.uri
}

output "location" {
  description = "Cloud Run サービスのリージョン"
  value       = google_cloud_run_v2_service.service.location
}
