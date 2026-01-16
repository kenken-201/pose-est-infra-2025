#!/bin/bash
set -e

# 環境変数インポートスクリプト
# -----------------------------------------------------------------------------
# .env ファイルを読み込み、Terraform 実行に必要な環境変数をエクスポートします。
# 呼び出し元のスクリプトで source して使用します。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

# .env 読み込み
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
else
  # 呼び出し元でエラーハンドリングするため、ここでは警告のみ
  echo "⚠️  .env ファイルが見つかりません: $ENV_FILE"
fi

# GCP_NOTIFICATION_EMAIL -> TF_VAR_gcp_notification_email マッピング
if [ -n "$GCP_NOTIFICATION_EMAIL" ]; then
  export TF_VAR_gcp_notification_email="$GCP_NOTIFICATION_EMAIL"
  # echo "📧 Notification Email set from environment."
fi

# R2 Account ID -> TF_VAR_r2_account_id
if [ -n "$CLOUDFLARE_ACCOUNT_ID" ]; then
  export TF_VAR_r2_account_id="$CLOUDFLARE_ACCOUNT_ID"
fi

# R2 Secret Key -> TF_VAR_r2_secret_access_key
if [ -n "$R2_SECRET_ACCESS_KEY" ]; then
  export TF_VAR_r2_secret_access_key="$R2_SECRET_ACCESS_KEY"
fi
