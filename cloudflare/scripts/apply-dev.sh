#!/bin/bash
set -e

# Terraform Apply 実行スクリプト (Dev 環境)
# -----------------------------------------------------------------------------
# 開発環境向けの terraform apply を実行します。
# 生成済みのプランファイル (dev.tfplan) が存在すれば適用し、なければ plan から実行します。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"
TF_DIR="$SCRIPT_DIR/../terraform/environments/dev"

# .env ファイルの読み込み
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

# GCP .env ファイルの読み込み (Shared Variables like Cloud Run URL)
GCP_ENV_FILE="$SCRIPT_DIR/../../gcp/.env"
if [ -f "$GCP_ENV_FILE" ]; then
  set -a
  source "$GCP_ENV_FILE"
  set +a
fi
echo "DEBUG: TF_VAR_dev_cloud_run_url is '${TF_VAR_dev_cloud_run_url}'"

# Zone ID Check & Normalize
if [ -n "$CLOUDFLARE_ZONE_ID" ]; then
  export TF_VAR_cloudflare_zone_id="$CLOUDFLARE_ZONE_ID"
elif [ -n "$TF_VAR_CLOUDFLARE_ZONE_ID" ]; then
  export TF_VAR_cloudflare_zone_id="$TF_VAR_CLOUDFLARE_ZONE_ID"
fi
export TF_VAR_cloudflare_account_id="$CLOUDFLARE_ACCOUNT_ID"

# Map Environment Specific Variable
if [ -n "$TF_VAR_dev_cloud_run_url" ]; then
  # plan-dev.sh will also do this, but apply needs it for consistent state if plan runs implicitly
  export TF_VAR_cloud_run_url="$TF_VAR_dev_cloud_run_url"
fi

cd "$TF_DIR"

echo "🚀 Terraform Apply を実行中 (Dev)..."
if [ -f "dev.tfplan" ]; then
  terraform apply "dev.tfplan"
else
  echo "⚠️ dev.tfplan が見つかりません。まず plan を実行します..."
  "$SCRIPT_DIR/plan-dev.sh"
  terraform apply "dev.tfplan"
fi

echo "✅ 適用が完了しました！"
