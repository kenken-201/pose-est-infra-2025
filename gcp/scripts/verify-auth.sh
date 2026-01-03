#!/bin/bash
set -e

# GCP 認証確認スクリプト
# -----------------------------------------------------------------------------
# ローカル環境が GCP アクセス用に正しく設定されているか検証します。
# gcloud CLI, プロジェクト設定, ADC, R2 クレデンシャル等をチェックします。

# 色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
ENV_FILE="$ROOT_DIR/.env"
CHECKS_PASSED=0
TOTAL_CHECKS=6

echo -e "${BLUE}${BOLD}🔍 GCP 認証環境を検証しています...${NC}"
echo ""

# .env の読み込み
if [ -f "$ENV_FILE" ]; then
  echo -e "📄 ${BOLD}.env${NC} から環境変数を読み込んでいます"
  set -a
  source "$ENV_FILE"
  set +a
else
  echo -e "${YELLOW}⚠️  警告: .env ファイルが $ENV_FILE に見つかりません${NC}"
fi

# ステータス表示関数
print_success() {
  echo -e "${GREEN}✅ $1${NC}"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
}

print_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
  if [ -n "$2" ]; then echo -e "   👉 $2"; fi
}

print_error() {
  echo -e "${RED}❌ エラー: $1${NC}"
  if [ -n "$2" ]; then echo -e "   👉 $2"; fi
}

# 1. gcloud CLI 認証チェック
echo -e "\n${BOLD}1️⃣  gcloud CLI 認証チェック...${NC}"
ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null || true)
if [ -n "$ACTIVE_ACCOUNT" ]; then
  print_success "ログイン中: $ACTIVE_ACCOUNT"
else
  print_error "gcloud CLI にログインしていません" "実行: gcloud auth login"
  # 終了せず、すべての問題を検出するため続行
fi

# 2. プロジェクト設定チェック
echo -e "\n${BOLD}2️⃣  プロジェクト設定チェック...${NC}"
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || true)
EXPECTED_PROJECT="${GCP_PROJECT_ID:-kenken-pose-est}"

if [ "$CURRENT_PROJECT" = "$EXPECTED_PROJECT" ]; then
  print_success "プロジェクト設定: $CURRENT_PROJECT"
else
  print_warning "現在のプロジェクトは '$CURRENT_PROJECT' です。推奨: '$EXPECTED_PROJECT'" \
    "実行: gcloud config set project $EXPECTED_PROJECT"
fi

# 3. Application Default Credentials (ADC) チェック
echo -e "\n${BOLD}3️⃣  Application Default Credentials (ADC) チェック...${NC}"
ADC_FILE="$HOME/.config/gcloud/application_default_credentials.json"
if [ -f "$ADC_FILE" ]; then
  print_success "ADC ファイルを確認しました: $ADC_FILE"
  
  if grep -q "$EXPECTED_PROJECT" "$ADC_FILE"; then
    echo -e "   (Quota プロジェクトは $EXPECTED_PROJECT と一致しているようです)"
  else
    echo -e "   ${YELLOW}(注: ADC の Quota プロジェクトが $EXPECTED_PROJECT と異なる可能性があります)${NC}"
  fi
else
  print_warning "ADC ファイルが見つかりません" "実行: gcloud auth application-default login"
fi

# 4. R2 クレデンシャルチェック (Terraform バックエンド用)
echo -e "\n${BOLD}4️⃣  R2 クレデンシャルチェック...${NC}"
if [ -n "$R2_ACCESS_KEY_ID" ] && [ -n "$R2_SECRET_ACCESS_KEY" ]; then
  print_success "環境変数に R2 クレデンシャルが設定されています"
else
  print_warning "R2 クレデンシャルが設定されていません" ".env に R2_ACCESS_KEY_ID と R2_SECRET_ACCESS_KEY を設定してください"
fi

# 5. Cloudflare アカウント ID チェック
echo -e "\n${BOLD}5️⃣  Cloudflare アカウント ID チェック...${NC}"
if [ -n "$CLOUDFLARE_ACCOUNT_ID" ]; then
  print_success "CLOUDFLARE_ACCOUNT_ID が設定されています"
else
  print_warning "CLOUDFLARE_ACCOUNT_ID が設定されていません" "Terraform バックエンドの初期化に必要です"
fi

# 6. プロジェクトアクセス権限テスト
echo -e "\n${BOLD}6️⃣  プロジェクトアクセス権限テスト...${NC}"
if gcloud projects describe "$EXPECTED_PROJECT" --format="value(lifecycleState)" &>/dev/null; then
  print_success "プロジェクトへのアクセスを確認しました: $EXPECTED_PROJECT"
else
  print_error "プロジェクト $EXPECTED_PROJECT にアクセスできません" \
    "権限を確認するか、'gcloud auth login' を再実行してください"
    
  echo -e "\n   ${BOLD}トラブルシューティング:${NC}"
  echo "   - アカウント ($ACTIVE_ACCOUNT) に 'Viewer' または 'Editor' ロールがあるか確認してください。"
  echo "   - 新規プロジェクトの場合は 'gcloud services enable cloudresourcemanager.googleapis.com' が実行されているか確認してください。"
fi

# チェック結果サマリー
echo -e "\n-----------------------------------------------------------"
if [ $CHECKS_PASSED -eq $TOTAL_CHECKS ]; then
  echo -e "${GREEN}${BOLD}🎉 すべてのチェックに合格しました！ ($CHECKS_PASSED/$TOTAL_CHECKS)${NC}"
  echo "Terraform インフラストラクチャのデプロイ準備が整いました。"
else
  echo -e "${YELLOW}${BOLD}⚠️  検証は警告/エラー付きで完了しました。 ($CHECKS_PASSED/$TOTAL_CHECKS 合格)${NC}"
  echo "上記の問題を解決してから Terraform を実行してください。"
  exit 1
fi
