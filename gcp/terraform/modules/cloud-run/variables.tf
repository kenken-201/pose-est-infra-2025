/*
  Cloud Run モジュール variables.tf
  -----------------------------------------------------------------------------
  Cloud Run サービス設定に必要な入力変数を定義します。
*/

variable "project_id" {
  description = "GCP プロジェクト ID"
  type        = string
}

variable "region" {
  description = "リージョン"
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

variable "ingress" {
  description = "Ingress トラフィック設定 (例: INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER)"
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"

  validation {
    condition     = contains(["INGRESS_TRAFFIC_ALL", "INGRESS_TRAFFIC_INTERNAL_ONLY", "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"], var.ingress)
    error_message = "Ingress 設定は 'INGRESS_TRAFFIC_ALL', 'INGRESS_TRAFFIC_INTERNAL_ONLY', 'INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER' のいずれかである必要があります。"
  }
}

variable "image_url" {
  description = "デプロイするコンテナイメージの URL (例: asia-northeast1-docker.pkg.dev/...)"
  type        = string
}

variable "service_account_email" {
  description = "Cloud Run サービスが使用するサービスアカウントのメールアドレス"
  type        = string
}

# R2 クレデンシャル (Secret Manager Secret IDs)
variable "r2_access_key_id_secret_id" {
  description = "R2 Access Key ID の Secret Manager Secret ID"
  type        = string
}

variable "r2_secret_access_key_secret_id" {
  description = "R2 Secret Access Key の Secret Manager Secret ID"
  type        = string
}

# R2 環境設定
variable "r2_account_id" {
  description = "Cloudflare Account ID"
  type        = string
}

variable "r2_bucket_name" {
  description = "R2 Bucket Name"
  type        = string
}

# 開発環境用の公開アクセス設定
variable "allow_unauthenticated" {
  description = "未認証アクセスを許可するか (true: allUsers に roles/run.invoker を付与)"
  type        = bool
  default     = false
}

# スケーリング設定
variable "min_instance_count" {
  description = "最小インスタンス数 (常時起動数)"
  type        = number
  default     = 0

  validation {
    condition     = var.min_instance_count >= 0
    error_message = "最小インスタンス数は 0 以上である必要があります。"
  }
}

variable "max_instance_count" {
  description = "最大インスタンス数"
  type        = number
  default     = 2

  validation {
    condition     = var.max_instance_count >= 1
    error_message = "最大インスタンス数は 1 以上である必要があります。"
  }
}

variable "max_request_concurrency" {
  description = "インスタンスあたりの最大同時リクエスト数"
  type        = number
  default     = 80

  validation {
    condition     = var.max_request_concurrency >= 1 && var.max_request_concurrency <= 1000
    error_message = "最大同時リクエスト数は 1 から 1000 の間である必要があります。"
  }
}

variable "cpu_idle" {
  description = "CPU アイドル時の割り当て解除 (true: リクエスト時のみ CPU 割り当て / false: 常時割り当て)"
  type        = bool
  default     = true
}

variable "startup_cpu_boost" {
  description = "起動時に一時的に CPU 割り当てを増やすか"
  type        = bool
  default     = true
}

# リソース制限
variable "cpu_limit" {
  description = "コンテナの CPU 上限 (例: '1', '2')"
  type        = string
  default     = "1"
}

variable "memory_limit" {
  description = "コンテナのメモリ上限 (例: '512Mi', '1Gi')"
  type        = string
  default     = "512Mi"
}

variable "labels" {
  description = "Cloud Run サービスに付与するラベル"
  type        = map(string)
  default     = {}
}
