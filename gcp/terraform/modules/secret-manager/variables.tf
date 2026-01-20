/*
  Secret Manager モジュール variables.tf
  -----------------------------------------------------------------------------
  Secret Manager 設定に必要な入力変数を定義します。
*/

variable "project_id" {
  description = "GCP プロジェクト ID"
  type        = string
}

variable "backend_access_token" {
  description = "Cloudflare Workers との認証用シークレットトークン"
  type        = string
  sensitive   = true
}

variable "r2_secret_access_key" {
  description = "Cloudflare R2 Secret Access Key"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "環境名 (dev, production)"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "環境名は 'dev' または 'prod' である必要があります。"
  }
}

variable "cloud_run_sa_member" {
  description = "Cloud Run サービスアカウントの IAM メンバー形式 (serviceAccount:...)"
  type        = string
}
