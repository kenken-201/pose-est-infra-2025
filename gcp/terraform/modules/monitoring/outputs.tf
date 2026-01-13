output "notification_channel_id" {
  description = "通知チャンネル ID"
  value       = google_monitoring_notification_channel.email.id
}

output "notification_channel_name" {
  description = "通知チャンネル表示名"
  value       = google_monitoring_notification_channel.email.display_name
}

output "alert_policy_ids" {
  description = "作成されたアラートポリシー ID のリスト"
  value = [
    google_monitoring_alert_policy.cloud_run_error_rate.id,
    google_monitoring_alert_policy.cloud_run_latency.id
  ]
}

output "alert_policy_names" {
  description = "作成されたアラートポリシー表示名のリスト"
  value = [
    google_monitoring_alert_policy.cloud_run_error_rate.display_name,
    google_monitoring_alert_policy.cloud_run_latency.display_name
  ]
}

output "monitoring_config_summary" {
  description = "監視設定のサマリー"
  value = {
    environment          = var.environment
    service_name         = var.service_name
    error_rate_threshold = "${var.error_rate_threshold * 100}%"
    latency_threshold    = "${var.latency_threshold_ms}ms"
  }
}
