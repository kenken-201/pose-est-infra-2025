#!/bin/bash
set -e

# Terraform Apply 実行スクリプト (Dev 環境)
# -----------------------------------------------------------------------------
# .env を読み込み、dev.tfplan を適用します。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"
TF_DIR="$SCRIPT_DIR/../terraform/environments/dev"

# .env 読み込み
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

# Terraform 用変数エクスポート
# (setup-secrets.sh で設定された CLOUDFLARE_ACCOUNT_ID を使用)
if [ -n "$CLOUDFLARE_ACCOUNT_ID" ]; then
  export TF_VAR_r2_account_id="$CLOUDFLARE_ACCOUNT_ID"
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
