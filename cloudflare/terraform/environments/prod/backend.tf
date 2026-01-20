/*
  Terraform バックエンド設定 (Production 環境)
  -----------------------------------------------------------------------------
  State の保存先として Cloudflare R2 (S3 互換) を使用します。
  Key: cloudflare/prod/terraform.tfstate
*/

terraform {
  backend "s3" {
    bucket                      = "pose-est-terraform-state"
    key                         = "cloudflare/prod/terraform.tfstate"
    region                      = "auto"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    encrypt                     = true # 暗号化を有効化
  }
}
