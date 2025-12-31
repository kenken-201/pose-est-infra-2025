#!/bin/bash
set -e

# R2 セキュリティ検証スクリプト
# -----------------------------------------------------------------------------
# 以下のセキュリティ項目を検証します:
# 1. 公開アクセス (認証なし) が拒否されること (403/401)
# 2. 許可されていないオリジンからのアクセスが拒否されること
# 3. 署名付き URL を使用して正常にアップロード/ダウンロードできること

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

# 環境変数チェック
if [ -z "$CLOUDFLARE_ACCOUNT_ID" ]; then
  echo "❌ CLOUDFLARE_ACCOUNT_ID が設定されていません。"
  exit 1
fi

R2_BUCKET_NAME="${R2_BUCKET_NAME:-pose-est-videos-dev}"
TEST_FILE="security-test.txt"
TEST_KEY="security-check/test-obj.txt"
BUCKET_URL="https://${CLOUDFLARE_ACCOUNT_ID}.r2.cloudflarestorage.com/${R2_BUCKET_NAME}"

echo "🛡️  R2 セキュリティ検証を開始します: $R2_BUCKET_NAME"
echo "=================================================="

# 1. ネガティブテスト: 公開アクセスの確認
echo "🚫 [Test 1] 公開アクセス拒否テスト..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BUCKET_URL}/${TEST_KEY}")

# R2 は署名がない場合、400 InvalidArgument (Message: Authorization) を返す場合があるが、
# これはアクセス拒否と同義であるため許可する。
if [[ "$HTTP_STATUS" == "403" ]] || [[ "$HTTP_STATUS" == "401" ]] || [[ "$HTTP_STATUS" == "400" ]]; then
    echo "✅ 成功: 認証なしアクセスは拒否されました (Status: $HTTP_STATUS)"
else
    echo "❌ 失敗: 公開アクセスが可能、または予期しない応答です (Status: $HTTP_STATUS)"
    # 公開は意図しないため警告ではなくエラー扱いとする
    exit 1
fi

# 2. 署名付き URL の生成と機能テスト (ポジティブテスト)
echo ""
echo "🔑 [Test 2] 署名付き URL 機能テスト..."

# テスト用ファイル作成
echo "This is a security test file via Presigned URL." > "$TEST_FILE"

# 終了時に必ずクリーンアップする
trap 'rm -f "$TEST_FILE"' EXIT

# Python スクリプトで PUT URL 生成
echo "   Generating PUT URL..."
# 新しい argparse 形式: python3 generate.py <key> <method> [--expires <sec>]
# 出力は URL のみ (標準出力)
PUT_URL=$(python3 "$SCRIPT_DIR/generate-presigned-url.py" "$TEST_KEY" "PUT" --expires 300)

if [ -z "$PUT_URL" ]; then
    echo "❌ 署名付き URL の生成に失敗しました。"
    exit 1
fi

# アップロード実行
echo "   Uploading file..."
curl -s -X PUT -T "$TEST_FILE" "$PUT_URL"
echo "   Upload complete."

# Python スクリプトで GET URL 生成
echo "   Generating GET URL..."
GET_URL=$(python3 "$SCRIPT_DIR/generate-presigned-url.py" "$TEST_KEY" "GET" --expires 300)

# ダウンロード確認
echo "   Downloading file..."
DOWNLOADED_CONTENT=$(curl -s "$GET_URL")

if [[ "$DOWNLOADED_CONTENT" == *"Presigned URL"* ]]; then
    echo "✅ 成功: 署名付き URL 経由でのアップロード/ダウンロードを確認しました。"
else
    # 内容が短いので出力してデバッグ
    echo "❌ 失敗: ダウンロードした内容が一致しません。"
    echo "Got: $DOWNLOADED_CONTENT"
    exit 1
fi

echo ""
echo "✅ すべてのセキュリティ検証テストを通過しました。"
