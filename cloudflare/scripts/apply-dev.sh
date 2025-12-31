#!/bin/bash
set -e

# Terraform Apply 実行スクリプト (Dev 環境)
# -----------------------------------------------------------------------------
# 開発環境向けの terraform apply を実行します。
# 生成済みのプランファイル (dev.tfplan) が存在すれば適用し、なければ plan から実行します。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

cd "$(dirname "$0")/../terraform"

echo "🚀 Terraform Apply を実行中 (Dev)..."
if [ -f "dev.tfplan" ]; then
  terraform apply "dev.tfplan"
else
  echo "⚠️ dev.tfplan が見つかりません。まず plan を実行します..."
  ../scripts/plan-dev.sh
  terraform apply "dev.tfplan"
fi

echo "✅ 適用が完了しました！"
