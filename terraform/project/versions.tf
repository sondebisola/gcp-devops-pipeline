terraform {
  required_version = ">= 1.7.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  # Local state for now — this is intentional. We can't point at a GCS
  # remote-state bucket until Terraform has created that bucket, so
  # bootstrap-level state stays local. We migrate to remote state in
  # Phase 3 once the bucket exists.
  backend "gcs" {
    bucket = "enterpriseai-459922-tfstate"
    prefix = "project"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}