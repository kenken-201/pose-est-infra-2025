#!/bin/bash
set -e

# Terraform バックエンド初期化スクリプト (GCP用)
# -----------------------------------------------------------------------------
# .env ファイルから環境変数を読み込み、R2 バックエンドを使用して Terraform を初期化します。
# 
# 使用方法:
#   ./scripts/init-backend.sh [環境ディレクトリパス]
#   例: ./scripts/init-backend.sh environments/dev
#   引数省略時は terraform/ ルートで実行します（非推奨）

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
ENV_FILE="$ROOT_DIR/.env"
TARGET_DIR="${1:-terraform}" # 引数がなければ terraform ルート (後方互換性)

# .env の読み込み
if [ -f "$ENV_FILE" ]; then
  echo "📄 .env ファイルから環境変数を読み込んでいます..."
  set -a
  source "$ENV_FILE"
  set +a
else
  echo "❌ エラー: .env ファイルが $ENV_FILE に見つかりません。"
  echo ".env.example を .env にコピーし、必要な値を設定してください。"
  exit 1
fi

# 必須変数のチェック
if [ -z "$CLOUDFLARE_ACCOUNT_ID" ] || [ -z "$R2_ACCESS_KEY_ID" ] || [ -z "$R2_SECRET_ACCESS_KEY" ]; then
  echo "❌ エラー: .env に必要な環境変数が不足しています。"
  echo "必須: CLOUDFLARE_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY"
  exit 1
fi

# ターゲットディレクトリへ移動
ABS_TARGET_DIR="$ROOT_DIR/$TARGET_DIR"
if [ ! -d "$ABS_TARGET_DIR" ]; then
  # terraform/からの相対パスとして再試行
  ABS_TARGET_DIR="$ROOT_DIR/terraform/$TARGET_DIR"
fi

if [ ! -d "$ABS_TARGET_DIR" ]; then
   echo "❌ エラー: ディレクトリ $TARGET_DIR が見つかりません。"
   exit 1
fi

cd "$ABS_TARGET_DIR"

echo "🚀 Terraform を初期化中 (R2 バックエンド)..."
echo "   対象: $ABS_TARGET_DIR"

terraform init \
  -backend-config="access_key=$R2_ACCESS_KEY_ID" \
  -backend-config="secret_key=$R2_SECRET_ACCESS_KEY" \
  -backend-config="endpoint=https://$CLOUDFLARE_ACCOUNT_ID.r2.cloudflarestorage.com"

echo "✅ Terraform の初期化が完了しました！"
