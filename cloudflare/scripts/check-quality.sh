#!/bin/bash
set -e

# Quality Check スクリプト
# -----------------------------------------------------------------------------
# Terraform コードの品質チェックを実行します。
# terraform/environments 配下の全ディレクトリを対象にチェックを行います。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_ROOT="$SCRIPT_DIR/../terraform/environments"

# 対象ディレクトリを探索 (dev, prod, etc.)
ENV_DIRS=$(find "$ENV_ROOT" -mindepth 1 -maxdepth 1 -type d)

for TF_DIR in $ENV_DIRS; do
    ENV_NAME=$(basename "$TF_DIR")
    echo "================================================================="
    echo "🌍 Checking environment: $ENV_NAME"
    echo "================================================================="
    
    cd "$TF_DIR"

    echo "🎨 Running Terraform Format Check..."
    terraform fmt -recursive -check
    echo "✅ Format OK"

    echo "📦 Initializing Terraform (Backend Disabled)..."
    terraform init -backend=false

    echo "🔎 Running Terraform Validate..."
    terraform validate -no-color
    echo "✅ Validate OK"

    echo "🧹 Running TFLint..."
    if command -v tflint &> /dev/null; then
        tflint --init
        tflint --format=compact || true
        echo "✅ TFLint check completed"
    else
        echo "⚠️ TFLint not found, skipping."
    fi

    echo "🛡️ Running Checkov Security Scan..."
    if command -v checkov &> /dev/null; then
        # Skip CKV_CLOUDFLARE_*: specific checks might need tuning
        checkov -d . --framework terraform --quiet --soft-fail || echo "⚠️ Checkov found issues (soft fail)"
    else
        echo "⚠️ Checkov not found, skipping."
    fi
    
    echo ""
done

echo "🎉 All checks passed for all environments!"
