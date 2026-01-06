#!/bin/bash
set -e

# Terraform Import スクリプト (Dev 環境)
# -----------------------------------------------------------------------------
# 既存リソースを Terraform 管理下にインポートします。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"
TF_DIR="$SCRIPT_DIR/../terraform/environments/dev"

# .env ファイルの読み込み
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

# 必須環境変数のチェック
if [ -z "$CLOUDFLARE_ACCOUNT_ID" ]; then
  echo "❌ エラー: CLOUDFLARE_ACCOUNT_ID が設定されていません"
  exit 1
fi

# Zone ID Check & Normalize
if [ -n "$CLOUDFLARE_ZONE_ID" ]; then
  export TF_VAR_cloudflare_zone_id="$CLOUDFLARE_ZONE_ID"
  ZONE_ID="$CLOUDFLARE_ZONE_ID"
elif [ -n "$TF_VAR_CLOUDFLARE_ZONE_ID" ]; then
  export TF_VAR_cloudflare_zone_id="$TF_VAR_CLOUDFLARE_ZONE_ID"
  ZONE_ID="$TF_VAR_CLOUDFLARE_ZONE_ID"
else
  echo "❌ エラー: CLOUDFLARE_ZONE_ID が設定されていません"
  exit 1
fi

# Terraform 変数の設定
export TF_VAR_cloudflare_account_id="$CLOUDFLARE_ACCOUNT_ID"

cd "$TF_DIR"

echo "📦 既存リソースをインポート中..."

# R2 バケット (ID format: <account_id>/<bucket_name>/<jurisdiction>)
echo "🗄️ R2 Bucket をインポート..."
terraform import module.r2_bucket.cloudflare_r2_bucket.this "$CLOUDFLARE_ACCOUNT_ID/pose-est-videos-dev/default" || echo "⚠️ R2 Bucket のインポートをスキップ"


# DNS レコード (SPF) - ID format: <zone_id>/<record_id>
echo "📧 SPF レコードをインポート..."
SPF_RECORD_ID="caf393e0899076aec3498b2423a2d1b3"
terraform import module.dns.cloudflare_dns_record.spf "$ZONE_ID/$SPF_RECORD_ID" || echo "⚠️ SPF レコードのインポートをスキップ"

# DNS レコード (DMARC) - ID format: <zone_id>/<record_id>
echo "📧 DMARC レコードをインポート..."
DMARC_RECORD_ID="5484a3b7b7a72a850c5ee3841ea9233f"
terraform import module.dns.cloudflare_dns_record.dmarc "$ZONE_ID/$DMARC_RECORD_ID" || echo "⚠️ DMARC レコードのインポートをスキップ"

echo "✅ インポート処理が完了しました"
