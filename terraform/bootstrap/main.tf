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

# -----------------------------------------------------------------------
# PROJECT-level grant #1: enabling APIs. This is the first thing
# terraform/project actually does (google_project_service resources), and
# it requires a project-scoped permission — bucket access alone doesn't
# cover it. Note this is intentionally narrow (serviceusage only), not
# roles/editor — more project-level roles get added here, one at a time,
# as later phases (networking, compute) introduce new resource types that
# need them. Each addition should be traceable to the phase that required
# it, same discipline as the bucket-scoped grant above.
# -----------------------------------------------------------------------
resource "google_project_iam_member" "pipeline_service_usage_admin" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageAdmin"
  member  = "serviceAccount:${google_service_account.terraform_pipeline.email}"
}

# -----------------------------------------------------------------------
# PROJECT-level grant #2: servicemanagement.admin. serviceUsageAdmin alone
# was NOT sufficient for google_project_service to succeed in practice —
# confirmed by direct testing on 2026-07-21, even though Policy
# Troubleshooter showed serviceusage.services.enable as granted. Adding
# this role is what actually resolved the "Error 403: The caller does not
# have permission" failures on google_project_service.apis.
# -----------------------------------------------------------------------
resource "google_project_iam_member" "pipeline_service_management_admin" {
  project = var.project_id
  role    = "roles/servicemanagement.admin"
  member  = "serviceAccount:${google_service_account.terraform_pipeline.email}"
}
