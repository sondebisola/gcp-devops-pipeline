# -----------------------------------------------------------------------
# Workload Identity Pool — a container for external identities. One pool
# can hold providers for multiple external systems (Azure DevOps, GitHub,
# etc.) if you add more later.
# -----------------------------------------------------------------------
resource "google_iam_workload_identity_pool" "azure_devops" {
  project                  = var.project_id
  workload_identity_pool_id = var.pool_id
  display_name              = "Azure DevOps"
  description                = "Identities from Azure DevOps service connections, used by CI/CD pipelines to authenticate without stored keys."
}

# -----------------------------------------------------------------------
# OIDC Provider — the actual trust configuration. This is the resource
# that says "tokens signed by THIS issuer, matching THIS condition, are
# acceptable."
# -----------------------------------------------------------------------
resource "google_iam_workload_identity_pool_provider" "azure_devops" {
  project                           = var.project_id
  workload_identity_pool_id         = google_iam_workload_identity_pool.azure_devops.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = "star-devops-mvp pipeline"

  oidc {
    issuer_uri        = var.azure_devops_issuer_uri
    # Fixed application ID of Microsoft's Azure Token Exchange Endpoint —
    # this value is the same for every Azure DevOps org, per Google's docs.
    # It is NOT specific to your tenant.
    allowed_audiences = ["fb60f99c-7a34-4190-8149-302f77469936"]
  }

  # The Azure DevOps subject claim is "<prefix>/sc/<service-connection>",
  # which exceeds the 127-char limit Google places on google.subject.
  # This mapping takes only the part after "/sc/".
  attribute_mapping = {
    "google.subject" = "assertion.sub.split('/sc/')[1]"
  }

  # Without this, ANY Azure DevOps organization's token could potentially
  # satisfy the issuer check alone. This condition pins trust to the
  # specific app registration behind YOUR service connection.
  attribute_condition = "assertion.oid=='${var.azure_devops_app_object_id}'"
}

# -----------------------------------------------------------------------
# Allow the federated identity to impersonate the terraform-pipeline SA.
# The pipeline never receives a GCP key — it exchanges its Azure DevOps
# token for short-lived impersonation credentials on this SA instead.
#
# Bound to the exact subject (this specific service connection), not a
# pool-wide wildcard — consistent with the least-privilege pattern used
# throughout this build. If you add a second Azure DevOps service
# connection to this same pool later, it will NOT automatically gain
# impersonation rights; that's a separate, deliberate grant.
# -----------------------------------------------------------------------
resource "google_service_account_iam_member" "pipeline_impersonation" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.pipeline_service_account_email}"
  role                = "roles/iam.workloadIdentityUser"
  member              = "principal://iam.googleapis.com/${google_iam_workload_identity_pool.azure_devops.name}/subject/${var.azure_devops_subject}"
}


#justspace for pipeline trigger