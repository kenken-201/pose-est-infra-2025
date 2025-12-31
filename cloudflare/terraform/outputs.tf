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

output "r2_bucket_domain" {
  description = "R2 バケットのドメイン"
  value       = module.r2_bucket.bucket_domain
  sensitive   = true
}
