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

# -----------------------------------------------------------------------------
# 環境変数 -> Terraform 入力変数 マッピング
# -----------------------------------------------------------------------------

# GCP プロジェクト ID
if [ -n "$GCP_PROJECT_ID" ]; then
  export TF_VAR_project_id="$GCP_PROJECT_ID"
fi

# リージョン
if [ -n "$GCP_REGION" ]; then
  export TF_VAR_region="$GCP_REGION"
fi

# GCP 通知用メールアドレス (モニタリングアラート送信先)
if [ -n "$GCP_NOTIFICATION_EMAIL" ]; then
  export TF_VAR_gcp_notification_email="$GCP_NOTIFICATION_EMAIL"
fi

# Cloudflare Account ID -> R2 Account ID (同一値)
if [ -n "$CLOUDFLARE_ACCOUNT_ID" ]; then
  export TF_VAR_r2_account_id="$CLOUDFLARE_ACCOUNT_ID"
fi

# -----------------------------------------------------------------------------
# シークレット変数 (センシティブ情報)
# -----------------------------------------------------------------------------

# R2 Secret Access Key (Cloudflare R2 ストレージ認証用)
if [ -n "$R2_SECRET_ACCESS_KEY" ]; then
  export TF_VAR_r2_secret_access_key="$R2_SECRET_ACCESS_KEY"
else
  echo "⚠️  R2_SECRET_ACCESS_KEY が未設定です (R2 接続に失敗する可能性があります)"
fi

# Backend Access Token (Cloudflare Workers <-> Cloud Run 認証用共有シークレット)
if [ -n "$BACKEND_ACCESS_TOKEN" ]; then
  export TF_VAR_backend_access_token="$BACKEND_ACCESS_TOKEN"
else
  echo "⚠️  BACKEND_ACCESS_TOKEN が未設定です (認証が機能しません)"
fi
