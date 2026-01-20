#!/bin/bash
set -e

# Terraform Backend 初期化ラッパー
# -----------------------------------------------------------------------------
# Python スクリプトを呼び出して R2 バケットの状態を確認・作成します。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

# .env ファイルの読み込みと環境変数のエクスポート
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 がインストールされていません。"
    exit 1
fi

echo "🚀 バックエンド初期化スクリプトを実行します..."
python3 "$SCRIPT_DIR/init-backend.py"
