output "workload_identity_pool_name" {
  description = "Full resource name of the pool."
  value       = google_iam_workload_identity_pool.azure_devops.name
}

output "workload_identity_provider_name" {
  description = "Full resource name of the provider — used to build the pipeline's audience string."
  value       = google_iam_workload_identity_pool_provider.azure_devops.name
}

output "workload_identity_provider_resource_path" {
  description = "The projects/<NUMBER>/locations/global/workloadIdentityPools/<pool>/providers/<provider> path needed in the pipeline's credential config audience field. NOTE: this uses var.project_id (the project ID string) as a placeholder — GCP's external_account audience actually requires the PROJECT NUMBER, not the project ID. Get the real number with: gcloud projects describe <project_id> --format='value(projectNumber)' and use that in the pipeline YAML instead of this output verbatim."
  value       = "projects/${var.project_id}/locations/global/workloadIdentityPools/${var.pool_id}/providers/${var.provider_id}"
}
