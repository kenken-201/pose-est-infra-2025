#!/bin/bash
set -e

# GCP インフラストラクチャ品質チェック用スクリプト
# -----------------------------------------------------------------------------
# Terraform のフォーマット、検証、TFLint、および Checkov セキュリティスキャンを実行します。
# 開発中および CI/CD パイプラインで使用されます。

# 色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
TERRAFORM_DIR="$ROOT_DIR/terraform"

echo -e "\n${YELLOW}🔍 GCP インフラストラクチャの品質チェックを開始します...${NC}\n"

# 1. Terraform フォーマットチェック
echo -e "${YELLOW}👉 Terraform フォーマットチェックを実行中...${NC}"
if terraform fmt -recursive -check "$TERRAFORM_DIR"; then
  echo -e "${GREEN}✅ フォーマット OK${NC}"
else
  echo -e "${RED}❌ フォーマットチェックに失敗しました。'terraform fmt -recursive' を実行して修正してください。${NC}"
  # 他のエラーも確認できるよう、ここでは終了しません
fi

# 2. Terraform 検証 (環境ごとにループ)
echo -e "\n${YELLOW}👉 Terraform 検証 (validate) を実行中...${NC}"

# 検証対象の環境ディレクトリ
ENV_DIRS=("$TERRAFORM_DIR/environments/dev")
# 新しい環境が増えた場合はここに追加してください

for dir in "${ENV_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    echo -e "   環境を確認中: $(basename "$dir")"
    pushd "$dir" > /dev/null
    
    # バックエンドなしで初期化 (高速・安全)
    terraform init -backend=false > /dev/null 2>&1
    
    if terraform validate -no-color; then
      echo -e "   ${GREEN}✅ 検証 OK ($(basename "$dir"))${NC}"
    else
      echo -e "   ${RED}❌ 検証失敗 ($(basename "$dir"))${NC}"
      exit 1
    fi
    popd > /dev/null
  fi
done

# 3. TFLint (Terraform リンター)
echo -e "\n${YELLOW}👉 TFLint を実行中...${NC}"
if command -v tflint &> /dev/null; then
  pushd "$TERRAFORM_DIR" > /dev/null
  tflint --init > /dev/null 2>&1
  
  # ルートディレクトリで実行
  echo "   ルートディレクトリを確認中..."
  tflint --format=compact
  
  # networking モジュールを確認
  echo "   モジュールを確認中: networking..."
  tflint --chdir=modules/networking --format=compact

  # gcp-project モジュールを確認
  echo "   モジュールを確認中: gcp-project..."
  tflint --chdir=modules/gcp-project --format=compact

  # iam モジュールを確認
  echo "   モジュールを確認中: iam..."
  tflint --chdir=modules/iam --format=compact
  
  # dev 環境を確認
  echo "   環境を確認中: dev..."
  tflint --chdir=environments/dev --format=compact

  echo -e "${GREEN}✅ TFLint チェック完了${NC}"
  popd > /dev/null
else
  echo -e "${YELLOW}⚠️ TFLint が見つかりません。スキップします。${NC}"
fi

# 4. Checkov (セキュリティスキャン)
echo -e "\n${YELLOW}👉 Checkov セキュリティスキャンを実行中...${NC}"
if command -v checkov &> /dev/null; then
  # Terraform ディレクトリ全体をスキャン
  # --soft-fail: チェック失敗時もビルドを中断しません（警告のみ）
  checkov -d "$TERRAFORM_DIR" --framework terraform --quiet --compact --soft-fail \
    --skip-check CKV_GCP_*: # 必要に応じて特定のチェックをスキップ
    
  echo -e "${GREEN}✅ Checkov スキャン完了${NC}"
else
  echo -e "${YELLOW}⚠️ Checkov が見つかりません。スキップします。${NC}"
fi

echo -e "\n${GREEN}🎉 すべてのチェックが完了しました！${NC}"
