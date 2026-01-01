/*
  Terraform バックエンド設定 (Dev)
  -----------------------------------------------------------------------------
  Cloudflare R2 を使用して State ファイルを管理します。
  キーは gcp/dev/terraform.tfstate です。
  クレデンシャルは初期化時に外部から渡されます。
*/

terraform {
  backend "s3" {
    bucket                      = "pose-est-terraform-state"
    key                         = "gcp/dev/terraform.tfstate" # dev 環境用の State キー
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
