/*
  入力変数 (Dev 環境)
  -----------------------------------------------------------------------------
  Cloudflare インフラストラクチャモジュールの入力変数を定義します。
  これらの変数により、インフラストラクチャのデプロイをカスタマイズできます。
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
  default     = ""
}

variable "environment" {
  description = "環境名 (dev, production)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "production"], var.environment)
    error_message = "環境名は 'dev' または 'production' である必要があります。"
  }
}

variable "domain_name" {
  description = "プライマリドメイン名"
  type        = string
  default     = "kenken-pose-est.online"
}

variable "cloud_run_url" {
  description = "Backend Cloud Run Service URL"
  type        = string
}

variable "backend_access_token" {
  description = "Backend Access Token (Shared Secret)"
  type        = string
  sensitive   = true
}

variable "cors_origins" {
  description = "Allowed CORS Origins"
  type        = list(string)
  default     = ["*"]
}

variable "additional_records" {
  description = "追加の DNS レコードリスト (サブドメイン等)"
  type = list(object({
    name    = string
    type    = string
    value   = string
    proxied = bool
    ttl     = number
    comment = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for r in var.additional_records : contains(["A", "AAAA", "CNAME", "TXT", "MX", "NS", "SPF", "SRV"], r.type)
    ])
    error_message = "DNS レコードタイプは A, AAAA, CNAME, TXT, MX, NS, SPF, SRV のいずれかである必要があります。"
  }
}
