#!/bin/bash
set -e

# register-r2-secrets.sh
# Cloudflare R2 のクレデンシャルを Secret Manager と GitHub Secrets に登録します。

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# デフォルト値
ENV="dev"
PROJECT_ID=$(gcloud config get-value project)

# ヘルプ表示
if [[ "$1" == "--help" ]]; then
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  --env <env>       Environment (default: dev)"
  echo "  --project <id>    GCP Project ID (default: current context)"
  exit 0
fi

# 引数解析
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --env) ENV="$2"; shift ;;
    --project) PROJECT_ID="$2"; shift ;;
    *) echo -e "${RED}Unknown parameter passed: $1${NC}"; exit 1 ;;
  esac
  shift
done

# 依存関係チェック
if ! command -v gcloud &> /dev/null; then
  echo -e "${RED}Error: 'gcloud' command is required but not found.${NC}"
  exit 1
fi

echo -e "${YELLOW}🔒 R2 クレデンシャル登録ツール (${ENV})${NC}"
echo "Project: ${PROJECT_ID}"
echo ""

# 確認プロンプト (誤操作防止)
read -p "Are you sure you want to register secrets to this project? (y/N) " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi
echo ""

# クレデンシャル入力
read -sp "Enter R2 Access Key ID: " ACCESS_KEY_ID
echo ""
read -sp "Enter R2 Secret Access Key: " SECRET_ACCESS_KEY
echo ""
echo ""

if [[ -z "$ACCESS_KEY_ID" || -z "$SECRET_ACCESS_KEY" ]]; then
  echo -e "${RED}Error: Access Key ID and Secret Access Key must be provided.${NC}"
  exit 1
fi

# Secret Manager への登録
echo -e "${YELLOW}👉 Secret Manager に登録中...${NC}"

# Access Key ID
echo -n "$ACCESS_KEY_ID" | gcloud secrets versions add "r2-access-key-id-${ENV}" \
  --project="${PROJECT_ID}" --data-file=-
echo -e "${GREEN}✅ Access Key ID registered to Secret Manager.${NC}"

# Secret Access Key
echo -n "$SECRET_ACCESS_KEY" | gcloud secrets versions add "r2-secret-access-key-${ENV}" \
  --project="${PROJECT_ID}" --data-file=-
echo -e "${GREEN}✅ Secret Access Key registered to Secret Manager.${NC}"

# GitHub Secrets への登録 (gh コマンド確認)
if command -v gh &> /dev/null; then
  echo ""
  echo -e "${YELLOW}👉 GitHub Secrets にも登録しますか？ (y/N)${NC}"
  read -r REGISTER_GH
  if [[ "$REGISTER_GH" =~ ^[Yy]$ ]]; then
    # リポジトリ確認などが必要だが、簡易的に register
    echo -n "$ACCESS_KEY_ID" | gh secret set "R2_ACCESS_KEY_ID_${ENV^^}"
    echo -n "$SECRET_ACCESS_KEY" | gh secret set "R2_SECRET_ACCESS_KEY_${ENV^^}"
    echo -e "${GREEN}✅ Registered to GitHub Secrets.${NC}"
  else
    echo "Skipped GitHub Secrets registration."
  fi
else
  echo -e "${YELLOW}⚠️ 'gh' command not found. Skipping GitHub Secrets registration.${NC}"
fi

echo ""
echo -e "${GREEN}🎉 完了しました！${NC}"
