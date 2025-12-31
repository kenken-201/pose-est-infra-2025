#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

cd "$(dirname "$0")/../terraform"

echo "🚀 Applying Terraform Plan (Dev)..."
if [ -f "dev.tfplan" ]; then
  terraform apply "dev.tfplan"
else
  echo "⚠️ dev.tfplan not found. Running plan first..."
  ../scripts/plan-dev.sh
  terraform apply "dev.tfplan"
fi

echo "✅ Apply successful!"
