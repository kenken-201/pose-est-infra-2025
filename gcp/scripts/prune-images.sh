#!/bin/bash
set -e

# Artifact Registry クリーンアップスクリプト
# -----------------------------------------------------------------------------
# 指定されたリポジトリ内の「タグが付いていない (Untagged)」イメージ、
# または特定のタグ以外を削除します。
#
# Usage: ./prune-images.sh

PROJECT_ID="kenken-pose-est"
REGION="asia-northeast1"
REPO_NAME="pose-est-backend-dev"
IMAGE_NAME="pose-est-backend"

IMAGE_PATH="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}"

echo "🔍 クリーンアップ対象: $IMAGE_PATH"

# イメージ一覧を取得 (Digest と Tag)
echo "📋 イメージ一覧を取得中..."
IMAGES=$(gcloud artifacts docker images list "$IMAGE_PATH" --include-tags --format="json")

# jq を使用して、'latest' タグが付いていないダイジェストを抽出
# 注意: 1つのダイジェストに複数のタグがある場合も考慮が必要ですが、
# ここでは単純に「tags リストに 'latest' を含まないもの」かつ「タグがないもの」を対象とします。

echo "🗑️  削除対象の抽出中..."

# 削除対象のダイジェストリストを作成
# 1. タグがない (untagged)
# 2. 'latest' タグを持っていない
DELETE_DIGESTS=$(echo "$IMAGES" | jq -r '
  .[] | 
  select(
    (.tags | length == 0) or 
    (.tags | index("latest") | not)
  ) | 
  .digest
')

if [ -z "$DELETE_DIGESTS" ]; then
  echo "✅ 削除対象のイメージはありませんでした。"
  exit 0
fi

echo "⚠️  以下のイメージを削除します:"
echo "$DELETE_DIGESTS"
echo ""

# ユーザー確認をスキップしたい場合はコメントアウトを外す
# read -p "これらを削除してよろしいですか？ (y/N): " confirm
# if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
#   echo "キャンセルしました。"
#   exit 0
# fi

for DIGEST in $DELETE_DIGESTS; do
  FULL_IMAGE="${IMAGE_PATH}@${DIGEST}"
  echo "🔥 Deleting: $DIGEST"
  gcloud artifacts docker images delete "$FULL_IMAGE" --delete-tags --quiet
done

echo "✨ クリーンアップ完了！"
