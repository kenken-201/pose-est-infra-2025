# ==============================================================================
# Cloudflare Pages Module Variables
# ==============================================================================


variable "account_id" {
  description = "Cloudflare アカウント ID"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[a-f0-9]{32}$", var.account_id))
    error_message = "アカウント ID は 32 文字の 16 進数文字列である必要があります。"
  }
}

variable "project_name" {
  description = "Pages プロジェクト名 (e.g. pose-est-frontend)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.project_name))
    error_message = "プロジェクト名は小文字の英数字とハイフンのみ使用可能です（先頭と末尾は英数字）。"
  }
}

variable "production_branch" {
  description = "本番環境として扱うブランチ名"
  type        = string
  default     = "main"
}

variable "build_config" {
  description = "ビルド設定"
  type = object({
    command         = optional(string, "npm run build")
    destination_dir = optional(string, "dist")
    root_dir        = optional(string, "") # モノレポの場合は指定
  })
  default = {}
}

variable "node_version" {
  description = "Node.js バージョン (環境変数 NODE_VERSION に設定されます)"
  type        = string
  default     = "20"
}

variable "compatibility_date" {
  description = "Cloudflare Workers/Pages 互換性日付 (YYYY-MM-DD)"
  type        = string
  default     = "2024-04-01"

  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-\\d{2}$", var.compatibility_date))
    error_message = "互換性日付は YYYY-MM-DD 形式である必要があります。"
  }
}

variable "preview_vars" {
  description = "プレビュー環境用の環境変数マップ"
  type        = map(string)
  default     = {}
}

variable "production_vars" {
  description = "本番環境用の環境変数マップ (自動的に NODE_VERSION がマージされます)"
  type        = map(string)
  default     = {}
}

