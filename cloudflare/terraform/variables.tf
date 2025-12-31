# -----------------------------------------------------------------------------
# Input Variables
# -----------------------------------------------------------------------------
# Define input variables for the Cloudflare infrastructure module.
# These variables allow customization of the infrastructure deployment.
# -----------------------------------------------------------------------------

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[a-f0-9]{32}$", var.cloudflare_account_id))
    error_message = "Cloudflare Account ID must be a 32-character hexadecimal string."
  }
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for kenken-pose-est.online"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name (dev, production)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "production"], var.environment)
    error_message = "Environment must be 'dev' or 'production'."
  }
}

variable "domain_name" {
  description = "Primary domain name"
  type        = string
  default     = "kenken-pose-est.online"
}
