#!/bin/bash
set -e

# test-r2-connection.sh
# AWS CLI (S3 互換) を使用して R2 への接続テストを行います。
# Cloudflare R2 は S3 API 互換であるため、aws s3 コマンドが使用可能です。

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# デフォルト値
ENV="dev"
ACCOUNT_ID="" # 必須

# ヘルプ表示
if [[ "$1" == "--help" ]]; then
  echo "Usage: $0 --account-id <id> [options]"
  echo ""
  echo "Options:"
  echo "  --account-id <id>  Cloudflare Account ID (Required)"
  echo "  --env <env>        Environment (default: dev)"
  echo ""
  echo "Prerequisites:"
  echo "  - 'aws' command (v2) must be installed."
  echo "  - Environment variables must be set manually for this test script:"
  echo "    export AWS_ACCESS_KEY_ID=<your-access-key>"
  echo "    export AWS_SECRET_ACCESS_KEY=<your-secret-key>"
  exit 0
fi

# 引数解析
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --account-id) ACCOUNT_ID="$2"; shift ;;
    --env) ENV="$2"; shift ;;
    *) echo -e "${RED}Unknown parameter passed: $1${NC}"; exit 1 ;;
  esac
  shift
done

if [[ -z "$ACCOUNT_ID" ]]; then
  echo -e "${RED}Error: --account-id is required.${NC}"
  exit 1
fi

BUCKET_NAME="pose-est-media-${ENV}"
ENDPOINT_URL="https://${ACCOUNT_ID}.r2.cloudflarestorage.com"

echo -e "${YELLOW}📡 Testing R2 Connection...${NC}"
echo "Environment: ${ENV}"
echo "Bucket:      ${BUCKET_NAME}"
echo "Endpoint:    ${ENDPOINT_URL}"
echo ""

# 依存関係チェック
if ! command -v aws &> /dev/null; then
  echo -e "${RED}Error: 'aws' command not found. Please install AWS CLI v2.${NC}"
  echo "Mac: brew install awscli"
  exit 1
fi

# クレデンシャルチェック
if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" ]]; then
  echo -e "${RED}Error: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY env vars are not set.${NC}"
  echo "Please export them before running this script."
  exit 1
fi

# R2 互換性: リージョン設定 (R2 は実際には無視するが AWS CLI の警告抑制のため)
export AWS_DEFAULT_REGION="auto"

# 接続テスト: バケット内のオブジェクト一覧取得 (ls)
echo -e "${YELLOW}Running: aws s3 ls s3://${BUCKET_NAME} ...${NC}"

if aws s3 ls "s3://${BUCKET_NAME}" --endpoint-url "${ENDPOINT_URL}"; then
  echo ""
  echo -e "${GREEN}✅ Connection Successful!${NC}"
  echo "Successfully listed objects in bucket '${BUCKET_NAME}'."
else
  echo ""
  echo -e "${RED}❌ Connection Failed.${NC}"
  echo "Check your Account ID, Bucket Name, and Credentials."
  exit 1
fi
