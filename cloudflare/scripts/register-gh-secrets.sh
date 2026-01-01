#!/bin/bash
set -e

# GitHub Secrets 登録スクリプト
# -----------------------------------------------------------------------------
# .env (または環境変数) から R2 のクレデンシャルを読み込み、
# GitHub CLI (gh) を使用してリポジトリの Secrets に登録します。
# 前提: `gh auth login` が完了していること。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

# .env ファイルの読み込み
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

echo "🔐 GitHub Secrets 登録ツール"
echo "----------------------------------------"

# Git リポジトリ内か確認
if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    echo "❌ 現在のディレクトリは Git リポジトリではありません。"
    exit 1
fi

# gh コマンドの確認
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) がインストールされていません。"
    echo "brew install gh 等でインストールしてください。"
    exit 1
fi

# ログイン状態の確認
if ! gh auth status &> /dev/null; then
    echo "❌ GitHub CLI にログインしていません。"
    echo "gh auth login を実行してください。"
    exit 1
fi

echo "以下のシークレットを GitHub に登録します:"
echo "1. R2_ACCESS_KEY_ID"
echo "2. R2_SECRET_ACCESS_KEY"
echo "3. CLOUDFLARE_API_TOKEN (存在する場合)"
echo "4. CLOUDFLARE_ACCOUNT_ID (存在する場合)"
echo "----------------------------------------"

read -p "実行しますか？ (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" ]] && [[ "$CONFIRM" != "Y" ]]; then
    echo "中止しました。"
    exit 0
fi

# シークレット登録関数
register_secret() {
    local key="$1"
    local value="$2"
    
    if [ -z "$value" ]; then
        echo "⚠️  ${key} が環境変数に見つかりません。スキップします。"
        return
    fi
    
    echo "📤 Registering ${key}..."
    echo "$value" | gh secret set "$key"
}

# 登録実行
register_secret "R2_ACCESS_KEY_ID" "$R2_ACCESS_KEY_ID"
register_secret "R2_SECRET_ACCESS_KEY" "$R2_SECRET_ACCESS_KEY"
register_secret "CLOUDFLARE_API_TOKEN" "$CLOUDFLARE_API_TOKEN"
register_secret "CLOUDFLARE_ACCOUNT_ID" "$CLOUDFLARE_ACCOUNT_ID"

echo "----------------------------------------"
echo "✅ GitHub Secrets への登録が完了しました。"
