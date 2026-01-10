output "custom_firewall_ruleset_id" {
  description = "ID of the Custom Firewall Ruleset"
  value       = cloudflare_ruleset.zone_level_custom_firewall.id
}
