#!/bin/bash
set -e

# R2 アクセスキー設定ヘルパー (ローカル用)
# -----------------------------------------------------------------------------
# ユーザーに対話形式で R2 の Access Key ID と Secret Access Key を入力させ、
# プロジェクトルートの .env ファイルに安全に追加・更新します。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

echo "🔐 R2 アクセスキー設定ヘルパー"
echo "----------------------------------------"
echo "Cloudflare Dashboard で発行した R2 トークン情報を入力してください。"
echo "発行手順: R2 > 'R2 API Tokens' > 'Create API Token'"
echo ""

# 入力プロンプト
read -p "R2 Access Key ID: " INPUT_ACCESS_KEY
if [ -z "$INPUT_ACCESS_KEY" ]; then
  echo "❌ Access Key ID が入力されませんでした。"
  exit 1
fi

read -s -p "R2 Secret Access Key: " INPUT_SECRET_KEY
echo ""
if [ -z "$INPUT_SECRET_KEY" ]; then
  echo "❌ Secret Access Key が入力されませんでした。"
  exit 1
fi

echo "----------------------------------------"

# .env ファイルが存在しない場合は作成
if [ ! -f "$ENV_FILE" ]; then
  echo "📄 .env ファイルを新規作成します..."
  touch "$ENV_FILE"
  chmod 600 "$ENV_FILE"
else
  # 既存ファイルのバックアップ作成
  cp "$ENV_FILE" "${ENV_FILE}.bak"
  echo "📦 既存の .env を .env.bak にバックアップしました。"
fi

# パーミッション設定 (600: 所有者のみ読み書き可)
chmod 600 "$ENV_FILE"

# ヘルパー関数: .env の値を更新または追加
update_env_var() {
  local key="$1"
  local value="$2"
  local file="$3"
  
  if grep -q "^${key}=" "$file"; then
    # 既存の行を置換 (OSX sed対応)
    sed -i '' "s|^${key}=.*|${key}=${value}|" "$file"
    echo "🔄 ${key} を更新しました。"
  else
    # 末尾に追記
    echo "${key}=${value}" >> "$file"
    echo "➕ ${key} を追加しました。"
  fi
}

# 環境変数の更新
update_env_var "R2_ACCESS_KEY_ID" "$INPUT_ACCESS_KEY" "$ENV_FILE"
update_env_var "R2_SECRET_ACCESS_KEY" "$INPUT_SECRET_KEY" "$ENV_FILE"

echo "----------------------------------------"
echo "✅ .env ファイルの更新が完了しました。"
echo "⚠️  注意: .env ファイルには機密情報が含まれます。絶対に git にコミットしないでください。"
