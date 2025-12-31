#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 is not installed."
    exit 1
fi

export R2_BUCKET_NAME="pose-est-videos-dev"

echo "🧪 Verifying R2 Bucket: $R2_BUCKET_NAME"
python3 "$SCRIPT_DIR/verify-r2.py"

echo "----------------------------------------"
echo "🌐 Verifying CORS (Curl)..."
# R2 Bucket URL
BUCKET_URL="https://${CLOUDFLARE_ACCOUNT_ID}.r2.cloudflarestorage.com/${R2_BUCKET_NAME}"

# Test CORS with curl
# Origin: https://kenken-pose-est.online (should be allowed)
response=$(curl -s -I -X OPTIONS "$BUCKET_URL" \
  -H "Origin: https://kenken-pose-est.online" \
  -H "Access-Control-Request-Method: PUT")

if echo "$response" | grep -q "Access-Control-Allow-Origin"; then
    echo "✅ CORS Verification Passed (Access-Control-Allow-Origin found)"
else
    echo "❌ CORS Verification Failed"
    echo "Response Headers:"
    echo "$response"
    # Don't exit 1 yet, maybe partial success
fi
