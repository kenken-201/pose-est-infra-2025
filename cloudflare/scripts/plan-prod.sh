#!/bin/bash
set -e

# Terraform Plan 実行スクリプト (Production 環境)
# -----------------------------------------------------------------------------
# 本番環境向けの terraform plan を実行します。

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

# 必須環境変数のチェック
if [ -z "$CLOUDFLARE_ACCOUNT_ID" ] || [ -z "$R2_ACCESS_KEY_ID" ] || [ -z "$R2_SECRET_ACCESS_KEY" ]; then
  echo "❌ エラー: 必要な環境変数が設定されていません (.env を確認してください)"
  exit 1
fi

# Zone ID Check (Production uses specific domain usually implied by main.tf vars, but good to have)
if [ -n "$CLOUDFLARE_ZONE_ID" ]; then
  export TF_VAR_cloudflare_zone_id="$CLOUDFLARE_ZONE_ID"
fi
export TF_VAR_cloudflare_account_id="$CLOUDFLARE_ACCOUNT_ID"

# -----------------------------------------------------------------------------
# 環境固有変数のマッピング
# -----------------------------------------------------------------------------
# Cloud Run URL (Prod 環境用)
if [ -n "$TF_VAR_prod_cloud_run_url" ]; then
  echo "✅ Cloud Run URL (Prod): ${TF_VAR_prod_cloud_run_url:0:50}..."
  export TF_VAR_cloud_run_url="$TF_VAR_prod_cloud_run_url"
else
  echo "⚠️  TF_VAR_prod_cloud_run_url が未設定です (Worker Proxy がデプロイされない可能性があります)"
fi

# Backend Access Token (Shared Secret for CF <-> GCP auth)
if [ -n "$BACKEND_ACCESS_TOKEN" ]; then
  echo "✅ Backend Access Token: [REDACTED] (${#BACKEND_ACCESS_TOKEN} chars)"
  export TF_VAR_backend_access_token="$BACKEND_ACCESS_TOKEN"
else
  echo "⚠️  BACKEND_ACCESS_TOKEN が未設定です (Worker から Cloud Run への認証が機能しません)"
fi

cd "$TF_DIR"

echo "📦 Terraform Backend を初期化中 (Prod)..."
terraform init \
  -reconfigure \
  -backend-config="access_key=$R2_ACCESS_KEY_ID" \
  -backend-config="secret_key=$R2_SECRET_ACCESS_KEY" \
  -backend-config="endpoint=https://$CLOUDFLARE_ACCOUNT_ID.r2.cloudflarestorage.com"

echo "📋 Terraform Plan を実行中 (Prod)..."
terraform plan -out=prod.tfplan
