output "exclusion_names" {
  description = "作成されたログ除外フィルター名のリスト"
  value = compact([
    try(google_logging_project_exclusion.exclude_health_check_success[0].name, null),
    try(google_logging_project_exclusion.exclude_debug_logs[0].name, null)
  ])
}

output "exclusion_ids" {
  description = "作成されたログ除外フィルター ID のリスト"
  value = compact([
    try(google_logging_project_exclusion.exclude_health_check_success[0].id, null),
    try(google_logging_project_exclusion.exclude_debug_logs[0].id, null)
  ])
}

output "exclusion_status" {
  description = "除外フィルターの有効/無効状態"
  value = {
    health_check_exclusion = {
      enabled  = var.exclude_health_check_logs
      disabled = var.disable_health_check_exclusion
    }
    debug_log_exclusion = {
      enabled  = var.environment == "prod" && var.exclude_debug_logs_in_prod
      disabled = var.disable_debug_log_exclusion
    }
  }
}
