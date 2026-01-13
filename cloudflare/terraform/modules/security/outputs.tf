output "custom_firewall_ruleset_id" {
  description = "ID of the Custom Firewall Ruleset"
  value       = cloudflare_ruleset.zone_level_custom_firewall.id
}

output "rate_limit_ruleset_id" {
  description = "ID of the Rate Limiting Ruleset"
  value       = cloudflare_ruleset.zone_level_rate_limit.id
}

output "security_headers_ruleset_id" {
  description = "ID of the Security Headers Ruleset"
  value       = cloudflare_ruleset.zone_level_security_headers.id
}
