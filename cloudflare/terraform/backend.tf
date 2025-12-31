/*
  Terraform バックエンド設定
  -----------------------------------------------------------------------------
  State の保存先として Cloudflare R2 (S3 互換) を使用します。
  
  重要: R2 は DynamoDB のようなネイティブの State ロックをサポートしていません。
  State ロックは CI/CD ジョブの直列化によって実現します。
  並列で terraform apply を実行しないようにしてください。

  初期化コマンド:
    terraform init \
      -backend-config="access_key=$R2_ACCESS_KEY_ID" \
      -backend-config="secret_key=$R2_SECRET_ACCESS_KEY" \
      -backend-config="endpoint=https://$CLOUDFLARE_ACCOUNT_ID.r2.cloudflarestorage.com"
*/

terraform {
  backend "s3" {
    # バケットは手動作成、またはブートストラップスクリプトで事前に作成する必要があります
    # 参照: scripts/init-backend.sh
    bucket                      = "pose-est-terraform-state"
    key                         = "cloudflare/terraform.tfstate"
    region                      = "auto"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    encrypt                     = true # 暗号化を有効化

    # クレデンシャルは -backend-config フラグ経由で提供されます
  }
}
