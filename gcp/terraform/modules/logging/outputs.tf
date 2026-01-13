output "exclusion_names" {
  description = "作成されたログ除外フィルター名のリスト"
  value = compact([
    var.exclude_health_check_logs ? google_logging_project_exclusion.exclude_health_check_success[0].name : null,
    var.environment == "prod" && var.exclude_debug_logs_in_prod ? google_logging_project_exclusion.exclude_debug_logs[0].name : null
  ])
}

output "exclusion_ids" {
  description = "作成されたログ除外フィルター ID のリスト"
  value = compact([
    var.exclude_health_check_logs ? google_logging_project_exclusion.exclude_health_check_success[0].id : null,
    var.environment == "prod" && var.exclude_debug_logs_in_prod ? google_logging_project_exclusion.exclude_debug_logs[0].id : null
  ])
}
