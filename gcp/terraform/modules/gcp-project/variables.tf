/*
  入力変数 - GCP プロジェクト基本設定
  -----------------------------------------------------------------------------
  モジュールの動作を制御する入力変数を定義します。
*/

variable "project_id" {
  description = "GCP プロジェクト ID"
  type        = string
}

variable "environment" {
  description = "環境名 (dev, production)"
  type        = string
}

variable "billing_account_id" {
  description = "予算アラート用の請求アカウント ID (省略可)"
  type        = string
  default     = ""
}

variable "budget_amount" {
  description = "月額予算設定 (USD)"
  type        = number
  default     = 20

  validation {
    condition     = var.budget_amount > 0
    error_message = "予算額は 0 より大きい必要があります。"
  }
}
