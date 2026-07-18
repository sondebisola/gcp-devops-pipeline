# -----------------------------------------------------------------------
# Remote state bucket
# -----------------------------------------------------------------------
resource "google_storage_bucket" "terraform_state" {
  name     = var.state_bucket_name
  project  = var.project_id
  location = var.region

  # Object versioning means a bad `apply` that corrupts state can be rolled
  # back to a prior version instead of losing state entirely.
  versioning {
    enabled = true
  }

  # Uniform bucket-level access: IAM only, no legacy per-object ACLs.
  # This is the current GCP best practice for any new bucket.
  uniform_bucket_level_access = true

  # Belt-and-suspenders against `terraform destroy` accidentally deleting
  # every module's state at once.
  lifecycle {
    prevent_destroy = true
  }
}

# -----------------------------------------------------------------------
# Service account the pipeline will authenticate as (via Workload Identity
# Federation in Phase 4 — no key file, ever). Created now with NO roles
# granted yet. We add roles incrementally, module by module, as each
# phase's resources make a specific permission necessary. That's the
# least-privilege discipline in practice: grant what's needed when it's
# needed, not everything up front "to be safe."
# -----------------------------------------------------------------------
resource "google_service_account" "terraform_pipeline" {
  project      = var.project_id
  account_id   = var.pipeline_sa_id
  display_name = "Terraform pipeline (Azure DevOps, via Workload Identity Federation)"
}

# The one role this SA needs immediately: read/write access to the state
# bucket itself. Scoped to the BUCKET, not the project — this SA cannot
# touch any other bucket in the project.
resource "google_storage_bucket_iam_member" "pipeline_state_access" {
  bucket = google_storage_bucket.terraform_state.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.terraform_pipeline.email}"
}
