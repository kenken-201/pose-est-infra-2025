/*
  Secret Manager モジュール variables.tf
  -----------------------------------------------------------------------------
  Secret Manager 設定に必要な入力変数を定義します。
*/

variable "project_id" {
  description = "GCP プロジェクト ID"
  type        = string
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
