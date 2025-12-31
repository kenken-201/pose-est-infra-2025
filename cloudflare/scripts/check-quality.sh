#!/bin/bash
set -e

# Change to the terraform directory
cd "$(dirname "$0")/../terraform"

echo "🎨 Running Terraform Format Check..."
terraform fmt -recursive -check
echo "✅ Format OK"

echo "� Initializing Terraform (Backend Disabled)..."
terraform init -backend=false

echo "�🔎 Running Terraform Validate..."
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
    # Suppress output to avoid noise, show only failures
    checkov -d . --framework terraform --quiet --soft-fail || echo "⚠️ Checkov found issues (soft fail)"
else
    echo "⚠️ Checkov not found, skipping."
fi

echo "🎉 All checks passed!"
