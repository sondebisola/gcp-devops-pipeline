output "state_bucket_name" {
  description = "Name of the GCS bucket holding Terraform remote state. Used in every other module's backend config."
  value       = google_storage_bucket.terraform_state.name
}

output "pipeline_service_account_email" {
  description = "Email of the service account the Azure DevOps pipeline will impersonate via Workload Identity Federation."
  value       = google_service_account.terraform_pipeline.email
}
