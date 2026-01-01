terraform {
  backend "s3" {
    bucket                      = "pose-est-terraform-state"
    key                         = "gcp/dev/terraform.tfstate" # dev環境用のStateキー
    region                      = "auto"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    encrypt                     = true
  }
}
