terraform {
  backend "s3" {
    bucket                      = "pose-est-terraform-state"
    key                         = "infra/terraform.tfstate"
    region                      = "auto"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    
    # Endpoint must be provided via -backend-config="endpoint=https://<ACCOUNT_ID>.r2.cloudflarestorage.com"
  }
}
