/*
  Terraform バックエンド設定
  -----------------------------------------------------------------------------
  State の保存先として Cloudflare R2 (S3 互換) を使用します。
  Cloudflare側のインフラ(pose-est-infra/cloudflare)と同一バケットで管理し、
  キーのみを分離することで、一元的な状態管理を実現します。

  重要: R2 は DynamoDB のようなネイティブの State ロックをサポートしていません。
  State ロックは CI/CD ジョブの直列化によって実現します。
  並列で terraform apply を実行しないようにしてください。

  初期化コマンド:
    推奨: ./scripts/init-backend.sh を使用してください。

    手動実行の場合:
    terraform init \
      -backend-config="access_key=$R2_ACCESS_KEY_ID" \
      -backend-config="secret_key=$R2_SECRET_ACCESS_KEY" \
      -backend-config="endpoint=https://$CLOUDFLARE_ACCOUNT_ID.r2.cloudflarestorage.com"
*/

terraform {
  backend "s3" {
    # バケットは pose-est-infra/cloudflare で既に作成済み
    # 初期化は scripts/init-backend.sh を使用してください
    bucket                      = "pose-est-terraform-state"
    key                         = "gcp/terraform.tfstate"
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
