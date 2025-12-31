/*
  出力値
  -----------------------------------------------------------------------------
  デプロイされたインフラストラクチャに関する主要な情報を公開するための出力値を定義します。
  これらの出力は、他のモジュールや CI/CD パイプラインとの連携に役立ちます。
*/

# 出力は以降のフェーズでリソースが作成される際に追加されます。
# 出力例:
#
# output "pages_url" {
#   description = "Cloudflare Pages デプロイメントの URL"
#   value       = cloudflare_pages_project.frontend.subdomain
# }
#
# output "r2_bucket_name" {
#   description = "動画保存用 R2 バケットの名前"
#   value       = cloudflare_r2_bucket.video_storage.name
# }
