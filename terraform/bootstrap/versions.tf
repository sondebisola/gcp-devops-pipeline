terraform {
  required_version = ">= 1.7.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  # This module's own state stays LOCAL, deliberately. It creates the
  # bucket that every OTHER module's remote state will live in — a module
  # can't use a backend that doesn't exist yet. Bootstrap state is small,
  # rarely changes, and you're the only one who runs it, so local is fine.
}

provider "google" {
  project = var.project_id
  region  = var.region
}
