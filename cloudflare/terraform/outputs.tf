# -----------------------------------------------------------------------------
# Output Values
# -----------------------------------------------------------------------------
# Define output values to expose key information about the deployed infrastructure.
# These outputs are useful for integration with other modules or CI/CD pipelines.
# -----------------------------------------------------------------------------

# Outputs will be added as resources are created in subsequent phases.
# Example outputs:
#
# output "pages_url" {
#   description = "URL of the Cloudflare Pages deployment"
#   value       = cloudflare_pages_project.frontend.subdomain
# }
#
# output "r2_bucket_name" {
#   description = "Name of the R2 bucket for video storage"
#   value       = cloudflare_r2_bucket.video_storage.name
# }
