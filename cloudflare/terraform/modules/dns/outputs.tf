# ==============================================================================
# DNS Module Outputs
# ==============================================================================

output "zone_id" {
  description = "管理対象の Cloudflare Zone ID"
  value       = var.zone_id
}

output "dnssec_ds_record" {
  description = "DNSSEC DS レコード情報 (レジストラへの登録用)"
  sensitive   = true # DS レコードはセキュリティ上機密扱い
  value = {
    key_tag     = cloudflare_zone_dnssec.this.key_tag
    algorithm   = cloudflare_zone_dnssec.this.algorithm
    digest      = cloudflare_zone_dnssec.this.digest
    digest_type = cloudflare_zone_dnssec.this.digest_type
    ds          = cloudflare_zone_dnssec.this.ds
  }
}

output "email_security_records" {
  description = "作成されたメールセキュリティレコード"
  value = {
    spf_record_id   = cloudflare_dns_record.spf.id
    dmarc_record_id = cloudflare_dns_record.dmarc.id
  }
}
