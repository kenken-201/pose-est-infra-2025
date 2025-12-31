# -----------------------------------------------------------------------------
# Main Terraform Configuration
# -----------------------------------------------------------------------------
# This file orchestrates all Cloudflare infrastructure modules.
# Modules will be added in subsequent phases:
#   - Phase 2: R2 Storage
#   - Phase 3: DNS
#   - Phase 4: Cloudflare Pages
#   - Phase 5: Security (WAF, Rate Limiting)
# -----------------------------------------------------------------------------

# Provider configuration
provider "cloudflare" {
  # API token is provided via CLOUDFLARE_API_TOKEN environment variable
}

# Local values for common configurations
locals {
  project_name = "pose-est"

  common_tags = {
    project     = local.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}
