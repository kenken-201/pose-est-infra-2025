#!/bin/bash
set -e

# Terraform Backend Initialization Script for GCP
# -----------------------------------------------------------------------------
# Loads environment variables from .env and initializes Terraform with R2 backend.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
ENV_FILE="$ROOT_DIR/.env"

# Load .env
if [ -f "$ENV_FILE" ]; then
  echo "📄 Loading environment variables from $ENV_FILE"
  set -a
  source "$ENV_FILE"
  set +a
else
  echo "❌ Error: .env file not found at $ENV_FILE"
  echo "Please copy .env.example to .env and fill in the required values."
  exit 1
fi

# Check required variables
if [ -z "$CLOUDFLARE_ACCOUNT_ID" ] || [ -z "$R2_ACCESS_KEY_ID" ] || [ -z "$R2_SECRET_ACCESS_KEY" ]; then
  echo "❌ Error: Missing required environment variables in .env"
  echo "Required: CLOUDFLARE_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY"
  exit 1
fi

# Navigate to terraform directory
cd "$ROOT_DIR/terraform"

echo "🚀 Initializing Terraform with R2 backend..."
terraform init \
  -backend-config="access_key=$R2_ACCESS_KEY_ID" \
  -backend-config="secret_key=$R2_SECRET_ACCESS_KEY" \
  -backend-config="endpoint=https://$CLOUDFLARE_ACCOUNT_ID.r2.cloudflarestorage.com"

echo "✅ Terraform initialized successfully!"
