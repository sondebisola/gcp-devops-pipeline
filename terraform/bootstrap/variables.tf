variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "Region for the state bucket."
  type        = string
  default     = "us-central1"
}

variable "state_bucket_name" {
  description = "Globally-unique GCS bucket name for Terraform remote state. Bucket names are global across ALL of GCP, not just your project, so this needs to be distinctive."
  type        = string
}

variable "pipeline_sa_id" {
  description = "Account ID (the part before @) for the service account the pipeline will eventually use."
  type        = string
  default     = "terraform-pipeline"
}
