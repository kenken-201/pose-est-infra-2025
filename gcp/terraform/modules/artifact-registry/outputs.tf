/*
  Artifact Registry モジュール outputs.tf
  -----------------------------------------------------------------------------
  作成された Artifact Registry リポジトリの情報を出力します。
*/

output "repository_id" {
  description = "Artifact Registry リポジトリ ID"
  value       = google_artifact_registry_repository.repo.repository_id
}

output "repository_name" {
  description = "Artifact Registry リポジトリ名"
  value       = google_artifact_registry_repository.repo.name
}

output "repository_url" {
  description = "Artifact Registry リポジトリ URL (Docker push/pull 用)"
  # format: LOCATION-docker.pkg.dev/PROJECT-ID/REPOSITORY-ID
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.repository_id}"
}
