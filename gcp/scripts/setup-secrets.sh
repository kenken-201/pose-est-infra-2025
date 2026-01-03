#!/bin/bash
set -e

# GCP Terraform 環境変数セットアップヘルパー
# -----------------------------------------------------------------------------
# ユーザーに対話形式で Cloudflare Account ID と R2 アクセスキーを入力させ、
# gcp ディレクトリ直下の .env ファイルに安全に追加・更新します。
# これにより、terraform init 時の Backend 認証や apply 時の変数注入を自動化します。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

echo "🔐 GCP Terraform 環境変数セットアップ"
echo "----------------------------------------"
echo "Terraform Backend (R2) および Cloud Run 連携に必要な情報を設定します。"
echo ""

# Cloudflare Account ID
read -p "Cloudflare Account ID: " INPUT_ACCOUNT_ID
if [ -z "$INPUT_ACCOUNT_ID" ]; then
  echo "❌ Cloudflare Account ID が入力されませんでした。"
  exit 1
fi

echo ""
echo "R2 API Token 情報を入力してください。"
echo "発行手順: Cloudflare Dashboard > R2 > 'R2 API Tokens' > 'Create API Token'"
echo "権限: 'Admin Read & Write' 推奨 (Terraform State 管理のため)"
echo ""

# R2 Access Key ID
read -p "R2 Access Key ID: " INPUT_ACCESS_KEY
if [ -z "$INPUT_ACCESS_KEY" ]; then
  echo "❌ Access Key ID が入力されませんでした。"
  exit 1
fi

# R2 Secret Access Key
read -s -p "R2 Secret Access Key: " INPUT_SECRET_KEY
echo ""
if [ -z "$INPUT_SECRET_KEY" ]; then
  echo "❌ Secret Access Key が入力されませんでした。"
  exit 1
fi

echo "----------------------------------------"

# .env ファイル作成
if [ ! -f "$ENV_FILE" ]; then
  echo "📄 .env ファイルを新規作成します..."
  touch "$ENV_FILE"
  chmod 600 "$ENV_FILE"
else
  cp "$ENV_FILE" "${ENV_FILE}.bak"
  echo "📦 既存の .env をバックアップしました (.env.bak)"
fi

chmod 600 "$ENV_FILE"

# ヘルパー関数
update_env_var() {
  local key="$1"
  local value="$2"
  local file="$3"
  
  if grep -q "^${key}=" "$file"; then
    sed -i '' "s|^${key}=.*|${key}=${value}|" "$file"
    echo "🔄 ${key} を更新しました。"
  else
    echo "${key}=${value}" >> "$file"
    echo "➕ ${key} を追加しました。"
  fi
}

# 変数更新
update_env_var "CLOUDFLARE_ACCOUNT_ID" "$INPUT_ACCOUNT_ID" "$ENV_FILE"
update_env_var "R2_ACCESS_KEY_ID" "$INPUT_ACCESS_KEY" "$ENV_FILE"
update_env_var "R2_SECRET_ACCESS_KEY" "$INPUT_SECRET_KEY" "$ENV_FILE"

echo "----------------------------------------"
echo "✅ セットアップ完了！"
echo "以下のスクリプトで Terraform を実行できます:"
echo "  ./scripts/plan-dev.sh"
echo "  ./scripts/apply-dev.sh"
