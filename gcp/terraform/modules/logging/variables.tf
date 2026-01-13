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

# -----------------------------------------------------------------------------
# 運用制御用変数（障害調査時の一時無効化用）
# -----------------------------------------------------------------------------

variable "disable_health_check_exclusion" {
  description = "ヘルスチェックログ除外フィルターを一時的に無効化するか（障害調査時に true）"
  type        = bool
  default     = false
}

variable "disable_debug_log_exclusion" {
  description = "DEBUG ログ除外フィルターを一時的に無効化するか（障害調査時に true）"
  type        = bool
  default     = false
}
