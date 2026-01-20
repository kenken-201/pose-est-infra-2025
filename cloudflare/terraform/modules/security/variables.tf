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

variable "enable_security_headers" {
  description = "Enable Security Headers (Transform Rules). Requires Zone Transform Rules Edit permission."
  type        = bool
  default     = true
}
