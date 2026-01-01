output "enabled_apis" {
  description = "List of enabled APIs"
  value       = [for api in google_project_service.apis : api.service]
}

output "project_id" {
  description = "The GCP Project ID"
  value       = var.project_id
}
