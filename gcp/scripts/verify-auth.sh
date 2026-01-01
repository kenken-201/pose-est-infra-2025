#!/bin/bash
set -e

# GCP Authentication Verification Script
# -----------------------------------------------------------------------------
# Verifies that the local environment is correctly configured for GCP access.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
ENV_FILE="$ROOT_DIR/.env"

echo "🔍 Verifying GCP Authentication..."
echo ""

# Load .env if exists
if [ -f "$ENV_FILE" ]; then
  echo "📄 Loading environment variables from .env"
  set -a
  source "$ENV_FILE"
  set +a
fi

# 1. Check gcloud CLI authentication
echo "1️⃣  Checking gcloud CLI authentication..."
ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null || true)
if [ -n "$ACTIVE_ACCOUNT" ]; then
  echo "✅ Logged in as: $ACTIVE_ACCOUNT"
else
  echo "❌ Error: Not logged in to gcloud CLI"
  echo "👉 Run: gcloud auth login"
  exit 1
fi

# 2. Check project configuration
echo ""
echo "2️⃣  Checking project configuration..."
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || true)
EXPECTED_PROJECT="${GCP_PROJECT_ID:-kenken-pose-est}"
if [ "$CURRENT_PROJECT" = "$EXPECTED_PROJECT" ]; then
  echo "✅ Project set to: $CURRENT_PROJECT"
else
  echo "⚠️  Warning: Current project is '$CURRENT_PROJECT', expected '$EXPECTED_PROJECT'"
  echo "👉 Run: gcloud config set project $EXPECTED_PROJECT"
fi

# 3. Check Application Default Credentials
echo ""
echo "3️⃣  Checking Application Default Credentials..."
ADC_FILE="$HOME/.config/gcloud/application_default_credentials.json"
if [ -f "$ADC_FILE" ]; then
  echo "✅ ADC file exists at: $ADC_FILE"
else
  echo "⚠️  Warning: ADC file not found"
  echo "👉 Run: gcloud auth application-default login"
fi

# 4. Check R2 credentials (for Terraform backend)
echo ""
echo "4️⃣  Checking R2 credentials..."
if [ -n "$R2_ACCESS_KEY_ID" ] && [ -n "$R2_SECRET_ACCESS_KEY" ]; then
  echo "✅ R2 credentials are set in environment"
else
  echo "⚠️  Warning: R2 credentials not set"
  echo "👉 Ensure R2_ACCESS_KEY_ID and R2_SECRET_ACCESS_KEY are set in .env"
fi

# 5. Check Cloudflare Account ID
echo ""
echo "5️⃣  Checking Cloudflare Account ID..."
if [ -n "$CLOUDFLARE_ACCOUNT_ID" ]; then
  echo "✅ CLOUDFLARE_ACCOUNT_ID is set"
else
  echo "⚠️  Warning: CLOUDFLARE_ACCOUNT_ID not set"
  echo "👉 Required for Terraform backend initialization"
fi

# 6. Test project access
echo ""
echo "6️⃣  Testing project access..."
if gcloud projects describe "$EXPECTED_PROJECT" --format="value(name)" &>/dev/null; then
  echo "✅ Successfully accessed project: $EXPECTED_PROJECT"
else
  echo "❌ Error: Cannot access project $EXPECTED_PROJECT"
  echo "👉 Check project permissions"
  exit 1
fi

echo ""
echo "🎉 Authentication verification completed!"
