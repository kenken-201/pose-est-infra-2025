variable "zone_id" {
  description = "Cloudflare Zone ID"
  type        = string

  validation {
    condition     = can(regex("^[a-f0-9]{32}$", var.zone_id))
    error_message = "Zone ID は 32 文字の 16 進数文字列である必要があります。"
  }
}

variable "domain_name" {
  description = "ドメイン名 (e.g. example.com)"
  type        = string
}
