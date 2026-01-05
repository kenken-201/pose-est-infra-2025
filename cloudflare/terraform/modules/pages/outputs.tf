# ==============================================================================
# Pages Module Outputs
# ==============================================================================

output "id" {
  description = "Pages プロジェクト ID"
  value       = cloudflare_pages_project.this.id
}

output "name" {
  description = "Pages プロジェクト名"
  value       = cloudflare_pages_project.this.name
}

output "subdomain" {
  description = "デフォルトの *.pages.dev サブドメイン"
  value       = cloudflare_pages_project.this.subdomain
}

output "domains" {
  description = "設定されたカスタムドメインのリスト"
  value       = cloudflare_pages_project.this.domains
}
