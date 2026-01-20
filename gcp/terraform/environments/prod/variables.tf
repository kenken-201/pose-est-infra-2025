/*
  入力変数 - Dev 環境
  -----------------------------------------------------------------------------
  開発環境固有のパラメータを定義します。
*/

variable "project_id" {
  description = "GCP プロジェクト ID"
  type        = string
}

variable "region" {
  description = "リージョン"
  type        = string
  default     = "asia-northeast1"
}

variable "environment" {
  description = "環境名"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "環境名は 'dev' または 'prod' である必要があります。"
  }
}

variable "r2_account_id" {
  description = "Cloudflare Account ID (R2 エンドポイント構築用)"
  type        = string
}

variable "gcp_notification_email" {
  description = "アラート通知先メールアドレス"
  type        = string
  default     = "" # 必須だが、Apply時に環境変数またはtfvarsで上書き推奨
}

variable "r2_secret_access_key" {
  description = "Cloudflare R2 Secret Access Key"
  type        = string
  sensitive   = true
}

variable "backend_access_token" {
  description = "Cloudflare Workers との認証用シークレットトークン"
  type        = string
  sensitive   = true
}
