terraform {
  required_version = ">= 1.7.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  backend "gcs" {
    bucket = "enterpriseai-459922-tfstate"
    prefix = "wif"
  }
}

provider "google" {
  project = var.project_id
}
