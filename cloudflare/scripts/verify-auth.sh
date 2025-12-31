#!/bin/bash

# Load environment variables if .env exists
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

echo "🔍 Verifying Cloudflare Authentication..."

if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
  echo "❌ Error: CLOUDFLARE_API_TOKEN is not set."
  echo "👉 Please set it in .env or your environment."
  exit 1
fi

# 1. Verify Account Access (Optional if Account ID is provided)
if [ -n "$CLOUDFLARE_ACCOUNT_ID" ]; then
  echo "2️⃣  Verifying Account Access ($CLOUDFLARE_ACCOUNT_ID)..."
  ACC_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID" \
       -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
       -H "Content-Type: application/json")
  
  ACC_NAME=$(echo "$ACC_RESPONSE" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
  
  if [ -n "$ACC_NAME" ]; then
    echo "✅ Account found: $ACC_NAME"
  else
    echo "⚠️  Could not verify account details. Check permissions or Account ID."
    echo "$ACC_RESPONSE"
  fi
fi

# 2. Check R2 Keys (Basic check if vars exist)
echo "3️⃣  Checking R2 Configuration..."
if [ -n "$R2_ACCESS_KEY_ID" ] && [ -n "$R2_SECRET_ACCESS_KEY" ]; then
  echo "✅ R2 Keys present in environment."
  echo "ℹ️  To fully verify R2, run 'make r2-test' (to be implemented)."
else
  echo "⚠️  R2_ACCESS_KEY_ID or R2_SECRET_ACCESS_KEY missing. Terraform backend init may fail."
fi

echo ""
echo "🎉 Authentication check completed!"
