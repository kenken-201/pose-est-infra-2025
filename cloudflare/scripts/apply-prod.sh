#!/bin/bash
set -e

# Terraform Apply 実行スクリプト (Production 環境)
# -----------------------------------------------------------------------------
# 本番環境向けの terraform apply を実行します。
# 生成済みのプランファイル (prod.tfplan) が存在すれば適用し、なければ plan から実行します。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"
TF_DIR="$SCRIPT_DIR/../terraform/environments/prod"

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

# Zone ID
if [ -n "$CLOUDFLARE_ZONE_ID" ]; then
  export TF_VAR_cloudflare_zone_id="$CLOUDFLARE_ZONE_ID"
fi
export TF_VAR_cloudflare_account_id="$CLOUDFLARE_ACCOUNT_ID"

# Map Environment Specific Variable
if [ -n "$TF_VAR_prod_cloud_run_url" ]; then
  export TF_VAR_cloud_run_url="$TF_VAR_prod_cloud_run_url"
fi

if [ -n "$BACKEND_ACCESS_TOKEN" ]; then
  export TF_VAR_backend_access_token="$BACKEND_ACCESS_TOKEN"
fi

cd "$TF_DIR"

echo "🚀 Terraform Apply を実行中 (Prod)..."
if [ -f "prod.tfplan" ]; then
  terraform apply "prod.tfplan"
else
  echo "⚠️ prod.tfplan が見つかりません。まず plan を実行します..."
  "$SCRIPT_DIR/plan-prod.sh"
  terraform apply "prod.tfplan"
fi

echo "✅ 本番環境への適用が完了しました！"
