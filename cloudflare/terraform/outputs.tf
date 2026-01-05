/*
  出力値
  -----------------------------------------------------------------------------
  デプロイされたインフラストラクチャに関する主要な情報を公開するための出力値を定義します。
  これらの出力は、他のモジュールや CI/CD パイプラインとの連携に役立ちます。
*/

output "r2_bucket_name" {
  description = "動画保存用 R2 バケットの名前"
  value       = module.r2_bucket.bucket_name
}

output "r2_retention_days" {
  description = "R2 バケットの保持期間 (日)"
  value       = module.r2_bucket.retention_days
}

output "dnssec_ds_record" {
  description = "DNSSEC DS Record (Registrar 設定用)"
  value       = module.dns.dnssec_ds_record
  sensitive   = true
}

output "r2_bucket_domain" {
  description = "R2 バケットのドメイン"
  value       = module.r2_bucket.bucket_domain
  sensitive   = true
}

output "pages_project_name" {
  description = "Cloudflare Pages プロジェクト名"
  value       = module.pages.name
}

output "pages_subdomain" {
  description = "Cloudflare Pages デフォルトサブドメイン"
  value       = module.pages.subdomain
}

output "pages_domains" {
  description = "Cloudflare Pages カスタムドメイン一覧"
  value       = module.pages.domains
}
