/*
  出力値 (Production 環境)
  -----------------------------------------------------------------------------
  デプロイされたインフラストラクチャに関する主要な情報を公開するための出力値を定義します。
*/

output "r2_bucket_name" {
  description = "動画保存用 R2 バケットの名前"
  value       = module.r2_bucket.bucket_name
}

output "r2_retention_days" {
  description = "R2 バケットの保持期間 (日)"
  value       = module.r2_bucket.retention_days
}

# Dev 環境で管理されているため出力不要
# output "dnssec_ds_record" {
#   description = "DNSSEC DS Record (Registrar 設定用)"
#   value       = module.dns.dnssec_ds_record
#   sensitive   = true
# }

output "r2_bucket_domain" {
  description = "R2 バケットのドメイン"
  value       = module.r2_bucket.bucket_domain
  sensitive   = true
}

output "workers_frontend_hostname" {
  description = "フロントエンド Workers のカスタムドメイン"
  value       = cloudflare_workers_custom_domain.frontend_prod.hostname
}
