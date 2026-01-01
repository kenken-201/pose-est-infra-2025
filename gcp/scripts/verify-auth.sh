#!/bin/bash
set -e

# GCP Authentication Verification Script
# -----------------------------------------------------------------------------
# Verifies that the local environment is correctly configured for GCP access.

# Colors and Formatting
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

echo -e "${BLUE}${BOLD}🔍 Verifying GCP Authentication Environment...${NC}"
echo ""

# Load .env if exists
if [ -f "$ENV_FILE" ]; then
  echo -e "📄 Loading environment variables from ${BOLD}.env${NC}"
  set -a
  source "$ENV_FILE"
  set +a
else
  echo -e "${YELLOW}⚠️  Warning: .env file not found at $ENV_FILE${NC}"
fi

# Function to print status
print_success() {
  echo -e "${GREEN}✅ $1${NC}"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
}

print_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
  if [ -n "$2" ]; then echo -e "   👉 $2"; fi
}

print_error() {
  echo -e "${RED}❌ Error: $1${NC}"
  if [ -n "$2" ]; then echo -e "   👉 $2"; fi
}

# 1. Check gcloud CLI authentication
echo -e "\n${BOLD}1️⃣  Checking gcloud CLI authentication...${NC}"
ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null || true)
if [ -n "$ACTIVE_ACCOUNT" ]; then
  print_success "Logged in as: $ACTIVE_ACCOUNT"
else
  print_error "Not logged in to gcloud CLI" "Run: gcloud auth login"
  # Don't exit immediately, let user see all issues
fi

# 2. Check project configuration
echo -e "\n${BOLD}2️⃣  Checking project configuration...${NC}"
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || true)
EXPECTED_PROJECT="${GCP_PROJECT_ID:-kenken-pose-est}"

if [ "$CURRENT_PROJECT" = "$EXPECTED_PROJECT" ]; then
  print_success "Project set to: $CURRENT_PROJECT"
else
  print_warning "Current project is '$CURRENT_PROJECT', expected '$EXPECTED_PROJECT'" \
    "Run: gcloud config set project $EXPECTED_PROJECT"
fi

# 3. Check Application Default Credentials (ADC)
echo -e "\n${BOLD}3️⃣  Checking Application Default Credentials...${NC}"
ADC_FILE="$HOME/.config/gcloud/application_default_credentials.json"
if [ -f "$ADC_FILE" ]; then
  print_success "ADC file found at: $ADC_FILE"
  
  # Optional: Check if ADC project matches (simple grep check as parsing JSON is complex without jq)
  if grep -q "$EXPECTED_PROJECT" "$ADC_FILE"; then
    echo -e "   (Quota project appears to match $EXPECTED_PROJECT)"
  else
    echo -e "   ${YELLOW}(Note: ADC quota project might differ from $EXPECTED_PROJECT)${NC}"
  fi
else
  print_warning "ADC file not found" "Run: gcloud auth application-default login"
fi

# 4. Check R2 credentials (for Terraform backend)
echo -e "\n${BOLD}4️⃣  Checking R2 credentials...${NC}"
if [ -n "$R2_ACCESS_KEY_ID" ] && [ -n "$R2_SECRET_ACCESS_KEY" ]; then
  print_success "R2 credentials are set in environment"
else
  print_warning "R2 credentials not set" "Ensure R2_ACCESS_KEY_ID and R2_SECRET_ACCESS_KEY are set in .env"
fi

# 5. Check Cloudflare Account ID
echo -e "\n${BOLD}5️⃣  Checking Cloudflare Account ID...${NC}"
if [ -n "$CLOUDFLARE_ACCOUNT_ID" ]; then
  print_success "CLOUDFLARE_ACCOUNT_ID is set"
else
  print_warning "CLOUDFLARE_ACCOUNT_ID not set" "Required for Terraform backend initialization"
fi

# 6. Test project access
echo -e "\n${BOLD}6️⃣  Testing project access...${NC}"
if gcloud projects describe "$EXPECTED_PROJECT" --format="value(lifecycleState)" &>/dev/null; then
  print_success "Successfully verified access to project: $EXPECTED_PROJECT"
else
  print_error "Cannot access project $EXPECTED_PROJECT" \
    "Check your permissions or run 'gcloud auth login' again"
    
  echo -e "\n   ${BOLD}Troubleshooting:${NC}"
  echo "   - Ensure your account ($ACTIVE_ACCOUNT) has 'Viewer' or 'Editor' role on the project."
  echo "   - Ensure 'gcloud services enable cloudresourcemanager.googleapis.com' has been run if this is a new project."
fi

# Summary
echo -e "\n-----------------------------------------------------------"
if [ $CHECKS_PASSED -eq $TOTAL_CHECKS ]; then
  echo -e "${GREEN}${BOLD}🎉 All checks passed! ($CHECKS_PASSED/$TOTAL_CHECKS)${NC}"
  echo "You are ready to proceed with Terraform infrastructure deployment."
else
  echo -e "${YELLOW}${BOLD}⚠️  Verification completed with warnings/errors. ($CHECKS_PASSED/$TOTAL_CHECKS passed)${NC}"
  echo "Please resolve the issues above before running Terraform."
  exit 1
fi
