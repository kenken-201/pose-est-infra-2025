output "bucket_name" {
  description = "R2 バケット名"
  value       = cloudflare_r2_bucket.this.name
}

output "bucket_domain" {
  description = "R2 バケットのドメイン (r2.cloudflarestorage.com のサブドメイン)"
  value       = "https://${var.account_id}.r2.cloudflarestorage.com/${cloudflare_r2_bucket.this.name}"
}
