# ==============================================================================
# DNS Module Variables
# ==============================================================================

variable "zone_id" {
  description = "Cloudflare Zone ID (32文字の16進数)"
  type        = string

  validation {
    condition     = can(regex("^[a-f0-9]{32}$", var.zone_id))
    error_message = "Zone ID は 32 文字の 16 進数文字列である必要があります。"
  }
}

variable "domain_name" {
  description = "管理対象のドメイン名 (e.g. example.com)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*\\.[a-z]{2,}$", var.domain_name))
    error_message = "有効なドメイン名を指定してください (例: example.com)。"
  }
}
