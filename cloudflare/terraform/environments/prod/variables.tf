/*
  入力変数 (Production 環境)
  -----------------------------------------------------------------------------
  Cloudflare インフラストラクチャモジュールの入力変数を定義します。
*/

variable "cloudflare_account_id" {
  description = "Cloudflare アカウント ID"
  type        = string
  sensitive   = true
  validation {
    condition     = can(regex("^[a-f0-9]{32}$", var.cloudflare_account_id))
    error_message = "Cloudflare アカウント ID は 32 文字の 16 進数文字列である必要があります。"
  }
}

variable "cloudflare_zone_id" {
  description = "kenken-pose-est.online の Cloudflare ゾーン ID"
  type        = string
}

variable "environment" {
  description = "環境名 (dev, production)"
  type        = string
  default     = "prod"
  validation {
    condition     = var.environment == "prod"
    error_message = "この環境は 'prod' である必要があります。"
  }
}

# module.dns が無効化されているため未使用
# variable "domain_name" {
#   description = "プライマリドメイン名"
#   type        = string
#   default     = "kenken-pose-est.online"
# }

variable "cors_origins" {
  description = "CORS 許可オリジンリスト"
  type        = list(string)
  default     = ["https://kenken-pose-est.online", "https://www.kenken-pose-est.online"]
}

# module.dns が無効化されているため未使用
# variable "additional_records" {
#   description = "追加の DNS レコードリスト"
#   type = list(object({
#     name    = string
#     type    = string
#     value   = string
#     proxied = bool
#     ttl     = number
#     comment = optional(string)
#   }))
#   default = []
# }

variable "cloud_run_url" {
  description = "GCP Cloud Run サービスの URL (Prod)"
  type        = string
  default     = ""
}

variable "backend_access_token" {
  description = "Backend Access Token (Shared Secret)"
  type        = string
  sensitive   = true
  default     = ""
}
