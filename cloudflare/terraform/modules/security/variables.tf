variable "zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, production)"
  type        = string
}

variable "enable_waf" {
  description = "Enable Managed WAF Rulesets"
  type        = bool
  default     = true
}

variable "security_level" {
  description = "Security Level (essentially off, low, medium, high, under_attack)"
  type        = string
  default     = "medium"
}
