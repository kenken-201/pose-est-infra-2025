variable "account_id" {
  description = "Cloudflare アカウント ID"
  type        = string

  validation {
    condition     = can(regex("^[a-f0-9]{32}$", var.account_id))
    error_message = "アカウント ID は 32 文字の 16 進数文字列である必要があります。"
  }
}

variable "bucket_name" {
  description = "R2 バケット名。小文字、英数字、ハイフンのみ使用可能。"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.bucket_name))
    error_message = "バケット名は小文字、英数字、ハイフンのみで構成される必要があります。"
  }
}

variable "location" {
  description = "バケットのロケーション (例: apac, enam, wnam, eeur, weur)"
  type        = string
  default     = "apac"

  # オプション: 既知の場所に対するバリデーション
  # R2 は新しい場所を追加するため、厳密すぎないバリデーションにしています
  validation {
    condition     = contains(["apac", "enam", "wnam", "eeur", "weur", "auto"], var.location)
    error_message = "ロケーションは apac, enam, wnam, eeur, weur, auto のいずれかである必要があります。"
  }
}

variable "cors_origins" {
  description = "許可された CORS オリジンのリスト"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.cors_origins) > 0
    error_message = "cors_origins には少なくとも 1 つのオリジンを指定する必要があります。"
  }
}

variable "retention_days" {
  description = "オブジェクトの保持日数 (ライフサイクル自動削除)"
  type        = number
  default     = 7

  validation {
    condition     = var.retention_days >= 1 && var.retention_days <= 365
    error_message = "retention_days は 1 ~ 365 日の範囲で指定する必要があります。"
  }
}
