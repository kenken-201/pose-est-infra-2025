/*
  Artifact Registry モジュール variables.tf
  -----------------------------------------------------------------------------
  Artifact Registry 設定に必要な入力変数を定義します。
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

variable "cloud_build_sa_member" {
  description = "Cloud Build サービスアカウントの IAM メンバー形式 (serviceAccount:...)"
  type        = string
}

variable "cloud_run_sa_member" {
  description = "Cloud Run サービスアカウントの IAM メンバー形式 (serviceAccount:...)"
  type        = string
}

variable "immutable_tags" {
  description = "Docker タグの不変性を有効にするか (true: 上書き禁止, false: 上書き許可)"
  type        = bool
  default     = false # 開発環境の柔軟性のためデフォルトは false
}
