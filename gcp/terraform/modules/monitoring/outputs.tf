# =============================================================================
# Monitoring Module - 出力変数
# =============================================================================

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
  value = compact([
    google_monitoring_alert_policy.cloud_run_error_rate.id,
    google_monitoring_alert_policy.cloud_run_latency.id,
    var.enable_resource_alerts ? google_monitoring_alert_policy.cloud_run_memory[0].id : null
  ])
}

output "alert_policy_names" {
  description = "作成されたアラートポリシー表示名のリスト"
  value = compact([
    google_monitoring_alert_policy.cloud_run_error_rate.display_name,
    google_monitoring_alert_policy.cloud_run_latency.display_name,
    var.enable_resource_alerts ? google_monitoring_alert_policy.cloud_run_memory[0].display_name : null
  ])
}

output "monitoring_config_summary" {
  description = "監視設定のサマリー (デバッグ・ドキュメント用)"
  value = {
    environment             = var.environment
    service_name            = var.service_name
    error_rate_threshold    = "${var.error_rate_threshold * 100}%"
    latency_threshold       = "${var.latency_threshold_ms}ms"
    memory_threshold        = "${var.memory_threshold_percent}%"
    alerts_enabled          = var.enable_alerts
    resource_alerts_enabled = var.enable_resource_alerts
  }
}
