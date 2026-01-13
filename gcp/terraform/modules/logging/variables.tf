variable "project_id" {
  description = "GCP プロジェクト ID"
  type        = string
}

variable "environment" {
  description = "環境名 (dev, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment は 'dev' または 'prod' である必要があります。"
  }
}

variable "exclude_health_check_logs" {
  description = "ヘルスチェック成功ログを除外するかどうか"
  type        = bool
  default     = true
}

variable "exclude_debug_logs_in_prod" {
  description = "本番環境で DEBUG レベルログを除外するかどうか"
  type        = bool
  default     = true
}
