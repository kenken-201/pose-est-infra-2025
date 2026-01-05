# ==============================================================================
# Cloudflare Pages Module Variables
# ==============================================================================

variable "account_id" {
  description = "Cloudflare アカウント ID"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Pages プロジェクト名 (e.g. pose-est-frontend)"
  type        = string
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
