#!/bin/bash
set -e

# R2 検証実行スクリプト
# -----------------------------------------------------------------------------
# Python 検証スクリプトと curl を使用した CORS 動作確認を一括実行します。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 がインストールされていません。"
    exit 1
fi

export R2_BUCKET_NAME="pose-est-videos-dev"

echo "🧪 R2 バケットの検証中: $R2_BUCKET_NAME"
python3 "$SCRIPT_DIR/verify-r2.py"

echo "----------------------------------------"
echo "🌐 CORS 動作確認 (Curl)..."
# R2 バケット URL
BUCKET_URL="https://${CLOUDFLARE_ACCOUNT_ID}.r2.cloudflarestorage.com/${R2_BUCKET_NAME}"

# curl で CORS プリフライトリクエストを擬似テスト
# Origin: https://kenken-pose-est.online (許可されているはず)
response=$(curl -s -I -X OPTIONS "$BUCKET_URL" \
  -H "Origin: https://kenken-pose-est.online" \
  -H "Access-Control-Request-Method: PUT")

if echo "$response" | grep -q "Access-Control-Allow-Origin"; then
    echo "✅ CORS 検証成功 (Access-Control-Allow-Origin が返却されました)"
else
    echo "❌ CORS 検証失敗"
    echo "レスポンスヘッダ:"
    echo "$response"
    # 部分的な成功の可能性があるため exit 1 はせず警告のみ
fi
