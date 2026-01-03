#!/bin/bash
set -e

# バックエンド初期イメージ Push スクリプト
# -----------------------------------------------------------------------------
# Cloud Run の初回デプロイに必要なコンテナイメージをビルドし、
# Artifact Registry に Push します。
#
# 前提:
#   - Artifact Registry が作成済みであること (terraform apply -target=module.artifact_registry)
#   - ../../pose-est-backend にバックエンドのソースコードがあること

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."

# 設定 (Terraform の設定と合わせる)
PROJECT_ID="kenken-pose-est"
REGION="asia-northeast1"
REPO_NAME="pose-est-backend-dev" # dev環境用
IMAGE_NAME="pose-est-backend"
TAG="latest"

# ソースコードのパス (infraディレクトリの隣にあると仮定)
SOURCE_DIR="$SCRIPT_DIR/../../../pose-est-backend"

echo "🔍 設定確認:"
echo "  Project: $PROJECT_ID"
echo "  Region:  $REGION"
echo "  Repo:    $REPO_NAME"
echo "  Source:  $SOURCE_DIR"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "❌ エラー: バックエンドのソースディレクトリが見つかりません: $SOURCE_DIR"
  echo "  パスを確認してください。"
  exit 1
fi

echo "🔐 Docker 認証設定 (gcloud)..."
gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet

# Cloud Build を使用してビルド & プッシュ
# ローカルの Docker 環境 (colima/buildx) に依存せず、GCP 上でビルドを行います。
CLOUDBUILD_CONFIG="${SCRIPT_DIR}/../cloudbuild/backend-build.yaml"

echo "☁️ Cloud Build Submit..."
echo "  Source: $SOURCE_DIR"
echo "  Config: $CLOUDBUILD_CONFIG"

gcloud builds submit "$SOURCE_DIR" \
  --config "$CLOUDBUILD_CONFIG" \
  --project "$PROJECT_ID" \
  --substitutions=_REGION="$REGION",_REPOSITORY="$REPO_NAME",_IMAGE_TAG="$TAG"

echo "✅ イメージの Build & Push が完了しました！"
echo "  これで terraform apply (Cloud Run の作成) が実行可能です。"
