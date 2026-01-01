/*
  GCP プロジェクト基本設定モジュール
  -----------------------------------------------------------------------------
  必須 API の有効化と予算アラートの設定を行います。
  このモジュールは、環境（dev/production）ごとに適用されることを想定しています。
*/

terraform {
  required_version = ">= 1.14.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

# -----------------------------------------------------------------------------
# 必須 API の有効化
# -----------------------------------------------------------------------------
resource "google_project_service" "apis" {
  for_each = toset([
    "run.googleapis.com",                  # Cloud Run: コンテナ実行
    "cloudbuild.googleapis.com",           # Cloud Build: CI/CD ビルド
    "artifactregistry.googleapis.com",     # Artifact Registry: コンテナイメージ保存
    "secretmanager.googleapis.com",        # Secret Manager: 機密情報管理 (R2 クレデンシャル等)
    "iam.googleapis.com",                  # IAM: アクセス権限管理
    "cloudresourcemanager.googleapis.com", # Resource Manager: プロジェクトメタデータ管理
    "monitoring.googleapis.com",           # Cloud Monitoring: 監視
    "logging.googleapis.com",              # Cloud Logging: ログ収集
    "cloudbilling.googleapis.com",         # Cloud Billing: 請求管理 (予算 API 用)
    "billingbudgets.googleapis.com"        # Budget API: 予算アラート用
  ])

  project                    = var.project_id
  service                    = each.key
  disable_on_destroy         = false
  disable_dependent_services = false # 誤って依存サービスを無効化しないよう false に設定

  # API 有効化は時間がかかる場合があるためタイムアウトを設定
  timeouts {
    create = "30m"
    update = "40m"
  }
}

# -----------------------------------------------------------------------------
# 予算アラート設定
# -----------------------------------------------------------------------------
resource "google_billing_budget" "budget" {
  count = var.billing_account_id != "" ? 1 : 0

  billing_account = var.billing_account_id
  display_name    = "Budget Alert - ${var.project_id} - ${var.environment}"

  budget_filter {
    projects = ["projects/${var.project_id}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = var.budget_amount
    }
  }

  threshold_rules {
    threshold_percent = 0.5 # 50% 消費で通知
  }
  threshold_rules {
    threshold_percent = 0.8 # 80% 消費で通知
  }
  threshold_rules {
    threshold_percent = 1.0 # 100% 消費で通知
  }
}
