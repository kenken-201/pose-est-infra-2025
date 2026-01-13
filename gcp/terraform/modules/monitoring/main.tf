# 通知チャンネル (Email)
# -----------------------------------------------------------------------------
resource "google_monitoring_notification_channel" "email" {
  description  = "Cloud Run Alert Notification Channel"
  display_name = "Cloud Monitoring Email Channel (${var.environment})"
  type         = "email"
  labels = {
    email_address = var.gcp_notification_email
  }
  project = var.project_id
}

# アラートポリシー: Cloud Run エラー率上昇
# -----------------------------------------------------------------------------
resource "google_monitoring_alert_policy" "cloud_run_error_rate" {
  display_name = "[${var.environment}] Cloud Run Error Rate High (> ${var.error_rate_threshold * 100}%)"
  combiner     = "OR"
  conditions {
    display_name = "Error Rate Condition"
    condition_threshold {
      # フィルタ: 指定サービスの 500番台エラー率
      filter = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${var.service_name}\" AND metric.type = \"run.googleapis.com/request_count\" AND metric.labels.response_code_class = \"5xx\""

      # 集計: 5分間のレート
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }

      comparison      = "COMPARISON_GT"
      threshold_value = var.error_rate_threshold
      duration        = "60s"
      trigger {
        count = 1
      }
    }
  }

  documentation {
    content   = "Cloud Run サービスの 5xx エラー率が閾値 (${var.error_rate_threshold * 100}%) を超えました。\n\n**対応手順:**\n1. Cloud Run のログを確認し、エラーの原因（アプリケーションバグ、依存サービス障害など）を特定してください。\n2. 直近のデプロイが原因であればロールバックを検討してください。\n3. 必要に応じて開発チームにエスカレーションしてください。"
    mime_type = "text/markdown"
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
  project               = var.project_id
}

# アラートポリシー: Cloud Run レスポンス遅延
# -----------------------------------------------------------------------------
resource "google_monitoring_alert_policy" "cloud_run_latency" {
  display_name = "[${var.environment}] Cloud Run Latency High (> ${var.latency_threshold_ms}ms)"
  combiner     = "OR"
  conditions {
    display_name = "Latency Condition"
    condition_threshold {
      filter = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${var.service_name}\" AND metric.type = \"run.googleapis.com/request_latencies\""

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_PERCENTILE_95" # 95パーセンタイル値
      }

      comparison      = "COMPARISON_GT"
      threshold_value = var.latency_threshold_ms
      duration        = "60s"
      trigger {
        count = 1
      }
    }
  }

  documentation {
    content   = "Cloud Run サービスの応答時間 (p95) が閾値 (${var.latency_threshold_ms}ms) を超えました。\n\n**対応手順:**\n1. トレース情報 (Cloud Trace) を確認し、ボトルネックを特定してください。\n2. CPU/メモリ使用率を確認し、リソース不足の可能性を調査してください。\n3. 依存サービス (R2 など) の遅延を確認してください。"
    mime_type = "text/markdown"
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
  project               = var.project_id
}
