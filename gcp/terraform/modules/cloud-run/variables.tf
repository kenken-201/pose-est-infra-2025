/*
  Cloud Run モジュール variables.tf
  -----------------------------------------------------------------------------
  Cloud Run サービス設定に必要な入力変数を定義します。
*/

variable "project_id" {
  description = "GCP プロジェクト ID"
  type        = string
}

variable "region" {
  description = "リージョン"
  type        = string
}

variable "environment" {
  description = "環境名 (dev, production)"
  type        = string

  validation {
    condition     = contains(["dev", "production"], var.environment)
    error_message = "環境名は 'dev' または 'production' である必要があります。"
  }
}

variable "image_url" {
  description = "デプロイするコンテナイメージの URL (例: asia-northeast1-docker.pkg.dev/...)"
  type        = string
}

variable "service_account_email" {
  description = "Cloud Run サービスが使用するサービスアカウントのメールアドレス"
  type        = string
}

# R2 クレデンシャル (Secret Manager Secret IDs)
variable "r2_access_key_id_secret_id" {
  description = "R2 Access Key ID の Secret Manager Secret ID"
  type        = string
}

variable "r2_secret_access_key_secret_id" {
  description = "R2 Secret Access Key の Secret Manager Secret ID"
  type        = string
}

# R2 環境設定
variable "r2_account_id" {
  description = "Cloudflare Account ID"
  type        = string
}

variable "r2_bucket_name" {
  description = "R2 Bucket Name"
  type        = string
}

# 開発環境用の公開アクセス設定
variable "allow_unauthenticated" {
  description = "未認証アクセスを許可するか (true: allUsers に roles/run.invoker を付与)"
  type        = bool
  default     = false
}
