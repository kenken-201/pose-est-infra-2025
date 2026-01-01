/*
  入力変数 - ネットワーキング設定
  -----------------------------------------------------------------------------
  VPC やサブネットの設定を制御する変数を定義します。
*/

variable "project_id" {
  description = "GCP プロジェクト ID"
  type        = string
}

variable "region" {
  description = "GCP リージョン"
  type        = string
}

variable "environment" {
  description = "環境名 (dev, production)"
  type        = string

  validation {
    condition     = contains(["dev", "production"], var.environment)
    error_message = "環境名は 'dev' または 'production' である必要があります。"
  }
}

variable "subnet_cidr" {
  description = "サブネットの CIDR 範囲 (例: 10.0.0.0/24)"
  type        = string

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "subnet_cidr は有効な CIDR ブロックである必要があります。"
  }
}
