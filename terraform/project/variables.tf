variable "project_id" {
  description = "GCP project ID (already exists — this Terraform does not create the project itself)."
  type        = string
}

variable "region" {
  description = "Default region for regional resources."
  type        = string
  default     = "us-central1"
}

variable "apis_to_enable" {
  description = "Google APIs required across this project's roadmap phases."
  type        = list(string)
  default = [
    "compute.googleapis.com",              # Compute Engine (Phase 6)
    "container.googleapis.com",            # GKE (Phase 6, optional)
    "storage.googleapis.com",              # Cloud Storage / Terraform state bucket (Phase 3)
    "iam.googleapis.com",                  # IAM (Phase 3)
    "iamcredentials.googleapis.com",       # Required for Workload Identity Federation token exchange (Phase 4)
    "sts.googleapis.com",                  # Security Token Service — also required for WIF (Phase 4)
    "cloudresourcemanager.googleapis.com", # Project-level operations
    "servicenetworking.googleapis.com",    # VPC peering / private services (Phase 5)
    "run.googleapis.com",                  # Cloud Run — for the agent, later
  ]
}
