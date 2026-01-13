#!/bin/bash
set -e

# Terraform Apply 実行スクリプト (Prod 環境)
# -----------------------------------------------------------------------------
# .env を読み込み、prod.tfplan を適用します。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"
TF_DIR="$SCRIPT_DIR/../terraform/environments/prod"

# 環境変数のインポート
source "$SCRIPT_DIR/import-vars.sh"

cd "$TF_DIR"

echo "🚀 Terraform Apply を実行中 (Prod)..."
if [ -f "prod.tfplan" ]; then
  terraform apply "prod.tfplan"
else
  echo "⚠️ prod.tfplan が見つかりません。まず plan を実行します..."
  "$SCRIPT_DIR/plan-prod.sh"
  terraform apply "prod.tfplan"
fi

echo "✅ 適用が完了しました！"
