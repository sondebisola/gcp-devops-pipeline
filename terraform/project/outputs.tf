output "enabled_apis" {
  description = "APIs enabled by this module."
  value       = [for api in google_project_service.apis : api.service]
}
