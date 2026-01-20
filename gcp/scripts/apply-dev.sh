#!/bin/bash
set -e

# Terraform Apply 実行スクリプト (Dev 環境)
# -----------------------------------------------------------------------------
# .env を読み込み、dev.tfplan を適用します。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"
TF_DIR="$SCRIPT_DIR/../terraform/environments/dev"

# 環境変数のインポート
source "$SCRIPT_DIR/import-vars.sh"

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
