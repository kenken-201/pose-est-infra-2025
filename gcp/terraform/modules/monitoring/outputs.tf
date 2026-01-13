output "notification_channel_id" {
  description = "通知チャンネル ID"
  value       = google_monitoring_notification_channel.email.id
}

output "alert_policy_ids" {
  description = "作成されたアラートポリシー ID のリスト"
  value = [
    google_monitoring_alert_policy.cloud_run_error_rate.id,
    google_monitoring_alert_policy.cloud_run_latency.id
  ]
}
