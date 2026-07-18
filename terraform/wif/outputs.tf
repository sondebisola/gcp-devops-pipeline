output "workload_identity_pool_name" {
  description = "Full resource name of the pool — used to construct the pipeline's audience string."
  value       = google_iam_workload_identity_pool.azure_devops.name
}

output "workload_identity_provider_name" {
  description = "Full resource name of the provider — used in the pipeline YAML's audience/credential config."
  value       = google_iam_workload_identity_pool_provider.azure_devops.name
}
