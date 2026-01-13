# 通知チャンネル (Email)
# -----------------------------------------------------------------------------
resource "google_monitoring_notification_channel" "email" {
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
  display_name = "[${var.environment}] Cloud Run Error Rate High (> 5%)"
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

      # 比較: 閾値 0.05 (5%)
      # 注: request_count は「数」なので、厳密な「率」を出すには MQL が必要だが、
      # ここでは簡易的に「単位時間あたりの5xxエラー数」で異常検知する方針とする。
      # 無料枠の範囲内でシンプルにするため、閾値を「数」で設定するか検討が必要だが、
      # ここでは一旦、request_count の rate (count/sec) が 0.05 (つまり20秒に1回) を超えたら発報とする。
      # ※ エラー「率」にするには metric.labels.response_code_class != "2xx" との比率が必要。
      # 標準UIで設定できるのは「数」ベースが基本。

      comparison      = "COMPARISON_GT"
      threshold_value = 0.05 # 0.05 count/sec = 3 errors / min
      duration        = "60s"
      trigger {
        count = 1
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
  project               = var.project_id
}

# アラートポリシー: Cloud Run レスポンス遅延
# -----------------------------------------------------------------------------
resource "google_monitoring_alert_policy" "cloud_run_latency" {
  display_name = "[${var.environment}] Cloud Run Latency High (> 5s)"
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
      threshold_value = 5000 # 5000ms = 5s (単位はミリ秒)
      duration        = "60s"
      trigger {
        count = 1
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
  project               = var.project_id
}
