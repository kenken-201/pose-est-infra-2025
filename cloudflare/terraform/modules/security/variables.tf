variable "zone_id" {
  description = "Cloudflare Zone ID"
  type        = string

  validation {
    condition     = can(regex("^[a-f0-9]{32}$", var.zone_id))
    error_message = "Zone ID must be a 32-character hexadecimal string."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, production)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}
