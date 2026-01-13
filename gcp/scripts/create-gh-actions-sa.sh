#!/bin/bash
# create-gh-actions-sa.sh
# GitHub Actions 用の Service Account を作成し、必要な権限を付与してキー(JSON)を発行します。

set -e

# 定数
SA_NAME="github-actions-deployer"
SA_DISPLAY_NAME="GitHub Actions Deployer"
KEY_FILE="gcp-sa-key.json"

# 現在のプロジェクトIDを取得
PROJECT_ID=$(gcloud config get-value project)
echo "Current Project ID: $PROJECT_ID"
echo "--------------------------------------------------"

if [ -z "$PROJECT_ID" ]; then
  echo "Error: Project ID is not set. Run 'gcloud config set project YOUR_PROJECT_ID' first."
  exit 1
fi

# 1. Service Account 作成
echo "1. Creating Service Account: $SA_NAME ..."
if gcloud iam service-accounts describe "${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" >/dev/null 2>&1; then
  echo "   Service Account already exists. Skipping creation."
else
  gcloud iam service-accounts create "$SA_NAME" --display-name="$SA_DISPLAY_NAME"
  echo "   Created."
fi

# 2. 権限付与
echo "2. Binding IAM Roles ..."
# 必要なロール一覧
ROLES=(
  "roles/artifactregistry.writer"       # Docker Image Push
  "roles/cloudbuild.builds.editor"      # Cloud Build 実行
  "roles/run.developer"                 # Cloud Run Deploy
  "roles/iam.serviceAccountUser"        # Cloud Run 実行用 SA を利用する権限
  "roles/storage.admin"                 # ソースコードアップロード (Cloud Build)
  "roles/serviceusage.serviceUsageConsumer" # API 利用権限
)

SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

for role in "${ROLES[@]}"; do
  echo "   Adding role: $role"
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="$role" \
    --condition=None \
    --quiet >/dev/null
done

# 3. キー発行
echo "3. Creating Key File: $KEY_FILE ..."
if [ -f "$KEY_FILE" ]; then
  echo "   Key file already exists in current directory. Skipping generation to avoid overwriting."
  echo "   To regenerate, delete '$KEY_FILE' and run this script again."
else
  gcloud iam service-accounts keys create "$KEY_FILE" \
    --iam-account="$SA_EMAIL"
  echo "   Key generated: $KEY_FILE"
fi

echo "--------------------------------------------------"
echo "✅ Setup Completed!"
echo ""
echo "以下のファイルの中身を GitHub Secrets (GCP_SA_KEY) に設定してください:"
echo "File: $(pwd)/$KEY_FILE"
echo "--------------------------------------------------"
