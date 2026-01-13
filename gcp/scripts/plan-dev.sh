#!/bin/bash
set -e

# Terraform Plan 実行スクリプト (Dev 環境)
# -----------------------------------------------------------------------------
# .env から環境変数を読み込み、terraform init と plan を実行します。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"
TF_DIR="$SCRIPT_DIR/../terraform/environments/dev"

# 環境変数のインポート
source "$SCRIPT_DIR/import-vars.sh"

# 必須変数のチェック
if [ -z "$CLOUDFLARE_ACCOUNT_ID" ] || [ -z "$R2_ACCESS_KEY_ID" ] || [ -z "$R2_SECRET_ACCESS_KEY" ]; then
  echo "❌ 必要な環境変数が不足しています。"
  exit 1
fi

cd "$TF_DIR"

echo "📦 Terraform Backend を初期化中..."
terraform init \
  -reconfigure \
  -backend-config="access_key=$R2_ACCESS_KEY_ID" \
  -backend-config="secret_key=$R2_SECRET_ACCESS_KEY" \
  -backend-config="endpoint=https://$CLOUDFLARE_ACCOUNT_ID.r2.cloudflarestorage.com"

echo "📋 Terraform Plan を実行中 (Dev)..."
terraform plan -out=dev.tfplan
