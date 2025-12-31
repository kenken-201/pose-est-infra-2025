# -----------------------------------------------------------------------------
# Terraform Backend Configuration
# -----------------------------------------------------------------------------
# Uses Cloudflare R2 (S3-compatible) for state storage.
# 
# IMPORTANT: R2 does not support native state locking like DynamoDB.
# State locking is achieved through CI/CD job serialization.
# Avoid running parallel terraform apply commands.
#
# Initialize with:
#   terraform init \
#     -backend-config="access_key=$R2_ACCESS_KEY_ID" \
#     -backend-config="secret_key=$R2_SECRET_ACCESS_KEY" \
#     -backend-config="endpoint=https://$CLOUDFLARE_ACCOUNT_ID.r2.cloudflarestorage.com"
# -----------------------------------------------------------------------------

terraform {
  backend "s3" {
    bucket                      = "pose-est-terraform-state"
    key                         = "cloudflare/terraform.tfstate"
    region                      = "auto"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    encrypt                     = true

    # Credentials provided via -backend-config flags
  }
}
