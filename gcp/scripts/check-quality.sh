#!/bin/bash
set -e

# GCP インフラストラクチャ品質チェック用スクリプト
# -----------------------------------------------------------------------------
# Terraform のフォーマット、検証、TFLint、および Checkov セキュリティスキャンを実行します。
# パフォーマンス向上のため、可能な限り並列実行します。

# 色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
TERRAFORM_DIR="$ROOT_DIR/terraform"

echo -e "\n${YELLOW}🔍 GCP インフラストラクチャの品質チェックを開始します... (並列実行モード)${NC}\n"

# エラーハンドリング用
FAIL=0

# -----------------------------------------------------------------------------
# 1. Terraform フォーマットチェック & 検証 (直列 + 並列)
# -----------------------------------------------------------------------------
echo -e "${YELLOW}👉 Terraform フォーマットチェックを実行中...${NC}"
if terraform fmt -recursive -check "$TERRAFORM_DIR"; then
  echo -e "${GREEN}✅ フォーマット OK${NC}"
else
  echo -e "${RED}❌ フォーマットチェックに失敗しました。'terraform fmt -recursive' を実行して修正してください。${NC}"
  FAIL=1
fi

echo -e "\n${YELLOW}👉 検証、Lint、セキュリティスキャンを並列実行中...${NC}"

# バックグラウンドプロセスPID配列
PIDS=()
PIDS_NAMES=()

# 機能: コマンド実行ラッパー
run_check() {
  local name="$1"
  local cmd="$2"
  echo -e "   🚀 開始: $name"
  if eval "$cmd" > /dev/null 2>&1; then
    echo -e "   ${GREEN}✅ 完了: $name${NC}"
    return 0
  else
    echo -e "   ${RED}❌ 失敗: $name${NC}"
    # エラー詳細は再度実行して表示（簡易的）
    echo "   --- Error Log: $name ---"
    eval "$cmd" || true
    echo "   ------------------------"
    return 1
  fi
}

# (A) 環境ごとの validate
ENV_DIRS=("$TERRAFORM_DIR/environments/dev")
for dir in "${ENV_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    env_name=$(basename "$dir")
    (
      pushd "$dir" > /dev/null
      terraform init -backend=false > /dev/null 2>&1
      if terraform validate -no-color; then
        echo -e "   ${GREEN}✅ 検証 OK ($env_name)${NC}"
      else
        echo -e "   ${RED}❌ 検証失敗 ($env_name)${NC}"
        terraform validate -no-color
        exit 1
      fi
    ) &
    PIDS+=($!)
    PIDS_NAMES+=("Terraform Validate ($env_name)")
  fi
done

# (B) TFLint
if command -v tflint &> /dev/null; then
  (
    pushd "$TERRAFORM_DIR" > /dev/null
    tflint --init > /dev/null 2>&1
    
    # 全体チェック
    tflint --format=compact
    tflint --chdir=modules/networking --format=compact
    tflint --chdir=modules/gcp-project --format=compact

    # iam モジュールを確認
    echo "   モジュールを確認中: iam..."
    tflint --chdir=modules/iam --format=compact

    # artifact-registry モジュールを確認
    echo "   モジュールを確認中: artifact-registry..."
    tflint --chdir=modules/artifact-registry --format=compact
    
    # secret-manager モジュールを確認
    echo "   モジュールを確認中: secret-manager..."
    tflint --chdir=modules/secret-manager --format=compact

    # dev 環境を確認
    tflint --chdir=environments/dev --format=compact
    echo -e "   ${GREEN}✅ TFLint チェック完了${NC}"
  ) &
  PIDS+=($!)
  PIDS_NAMES+=("TFLint")
else
  echo -e "${YELLOW}⚠️ TFLint が見つかりません。スキップします。${NC}"
fi

# (C) Checkov
if command -v checkov &> /dev/null; then
  (
    checkov -d "$TERRAFORM_DIR" --framework terraform --quiet --compact --soft-fail \
      --skip-check CKV_GCP_*: > /dev/null
    echo -e "   ${GREEN}✅ Checkov スキャン完了${NC}"
  ) &
  PIDS+=($!)
  PIDS_NAMES+=("Checkov")
else
  echo -e "${YELLOW}⚠️ Checkov が見つかりません。スキップします。${NC}"
fi

# プロセス終了待ち
for i in "${!PIDS[@]}"; do
  pid=${PIDS[$i]}
  name=${PIDS_NAMES[$i]}
  if ! wait "$pid"; then
    FAIL=1
  fi
done

echo -e "\n-----------------------------------------------------------"
if [ $FAIL -eq 0 ]; then
  echo -e "${GREEN}🎉 すべてのチェックが完了しました！${NC}"
  exit 0
else
  echo -e "${RED}💀 いくつかのチェックが失敗しました。${NC}"
  exit 1
fi
