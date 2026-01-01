output "zone_id" {
  description = "Cloudflare Zone ID"
  value       = var.zone_id
}

output "dnssec_ds_record" {
  description = "DNSSEC DS Record (Registrar configuration)"
  value = {
    key_tag    = cloudflare_zone_dnssec.this.key_tag
    algorithm  = cloudflare_zone_dnssec.this.algorithm
    digest     = cloudflare_zone_dnssec.this.digest
    digest_type = cloudflare_zone_dnssec.this.digest_type
    ds         = cloudflare_zone_dnssec.this.ds
  }
}
