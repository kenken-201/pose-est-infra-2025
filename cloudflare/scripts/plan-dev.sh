#!/bin/bash
set -e

# Terraform Plan 実行スクリプト (Dev 環境)
# -----------------------------------------------------------------------------
# 開発環境向けの terraform plan を実行します。
# 必要な環境変数を読み込み、バックエンドを初期化した上で plan を生成します。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

# .env ファイルの読み込み
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

# 必須環境変数のチェック
if [ -z "$CLOUDFLARE_ACCOUNT_ID" ] || [ -z "$R2_ACCESS_KEY_ID" ] || [ -z "$R2_SECRET_ACCESS_KEY" ]; then
  echo "❌ エラー: 必要な環境変数が設定されていません (.env を確認してください)"
  exit 1
fi

# Terraform 変数の設定
export TF_VAR_cloudflare_account_id="$CLOUDFLARE_ACCOUNT_ID"

cd "$(dirname "$0")/../terraform"

echo "📦 Terraform Backend を初期化中..."
terraform init \
  -reconfigure \
  -backend-config="access_key=$R2_ACCESS_KEY_ID" \
  -backend-config="secret_key=$R2_SECRET_ACCESS_KEY" \
  -backend-config="endpoint=https://$CLOUDFLARE_ACCOUNT_ID.r2.cloudflarestorage.com"

echo "📋 Terraform Plan を実行中 (Dev)..."
terraform plan \
  -var-file="environments/dev/terraform.tfvars" \
  -out=dev.tfplan
