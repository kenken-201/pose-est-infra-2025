variable "project_id" {
  description = "GCP プロジェクト ID"
  type        = string
}

variable "gcp_notification_email" {
  description = "アラート通知先メールアドレス"
  type        = string
  sensitive   = true # ログ出力抑制

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.gcp_notification_email))
    error_message = "有効なメールアドレス形式である必要があります。"
  }
}

variable "environment" {
  description = "環境名 (dev, prod)"
  type        = string
}

variable "service_name" {
  description = "監視対象の Cloud Run サービス名"
  type        = string
}
