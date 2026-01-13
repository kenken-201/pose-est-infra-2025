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

variable "error_rate_threshold" {
  description = "アラートを発報するエラー率の閾値（0.0〜1.0）。例: 0.05 = 5%"
  type        = number
  default     = 0.05

  validation {
    condition     = var.error_rate_threshold > 0 && var.error_rate_threshold <= 1
    error_message = "エラー率は 0 より大きく 1 以下である必要があります。"
  }
}

variable "latency_threshold_ms" {
  description = "アラートを発報するレスポンス遅延の閾値（ミリ秒）。例: 5000 = 5秒"
  type        = number
  default     = 5000

  validation {
    condition     = var.latency_threshold_ms > 0
    error_message = "遅延閾値は正の整数である必要があります。"
  }
}

variable "service_name" {
  description = "監視対象の Cloud Run サービス名"
  type        = string
}
