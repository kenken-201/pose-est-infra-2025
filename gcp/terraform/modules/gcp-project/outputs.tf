/*
  出力値 - GCP プロジェクト基本設定
  -----------------------------------------------------------------------------
  モジュールの実行結果として得られる値を定義します。
*/

output "enabled_apis" {
  description = "有効化された API のリスト"
  value       = [for api in google_project_service.apis : api.service]
}

output "project_id" {
  description = "GCP プロジェクト ID"
  value       = var.project_id
}
