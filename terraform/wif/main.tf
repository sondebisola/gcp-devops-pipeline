# -----------------------------------------------------------------------
# Workload Identity Pool — a container for external identities.
# -----------------------------------------------------------------------
resource "google_iam_workload_identity_pool" "azure_devops" {
  project                   = var.project_id
  workload_identity_pool_id = var.pool_id
  display_name              = "Azure DevOps"
  description               = "Identities from Azure DevOps service connections, used by CI/CD pipelines to authenticate without stored keys."
}

# -----------------------------------------------------------------------
# OIDC Provider — the trust configuration.
#
# CONFIRMED AGAINST ACTUAL AZURE DEVOPS PORTAL SCREENSHOTS (2026-07):
# This organization's service connections use the newer Microsoft
# Entra-issued token flow, NOT the older Azure DevOps-native
# vstoken.dev.azure.com flow described in most public guides. The two
# flows are mutually exclusive and use different issuer hosts, subject
# formats, and audiences:
#
#   Legacy (vstoken.dev.azure.com):
#     issuer  = https://vstoken.dev.azure.com/<org-GUID>
#     subject = sc://<org>/<project>/<connection>   (short, ~46 chars)
#     audience = api://AzureADTokenExchange
#
#   Entra-issued (THIS environment, confirmed from the portal):
#     issuer  = https://login.microsoftonline.com/<tenant-GUID>/v2.0
#     subject = /eid1/c/pub/t/.../sc/<guid>/<guid>   (long, ~138 chars —
#               exceeds Google's 127-char limit, split() required)
#     audience = fb60f99c-7a34-4190-8149-302f77469936  (Microsoft's fixed
#               app ID for Azure DevOps in Entra, when Entra is the issuer)
#
# Always verify which flow applies by reading the actual "Workload
# Identity federation details" on the service connection's Overview tab
# — don't assume based on a generic guide.
# -----------------------------------------------------------------------
resource "google_iam_workload_identity_pool_provider" "azure_devops" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.azure_devops.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = "${var.provider_id} pipeline"

  oidc {
    issuer_uri        = var.azure_devops_issuer_uri
    allowed_audiences = ["fb60f99c-7a34-4190-8149-302f77469936"]
  }

  # Subject exceeds Google's 127-char limit for google.subject in this
  # flow, so we map only the part after "/sc/" — verified against the
  # actual subject string, not assumed.
  attribute_mapping = {
    "google.subject" = "assertion.sub.split('/sc/')[1]"
  }

  # Pins trust to the specific app registration behind YOUR service
  # connection.
  attribute_condition = "assertion.oid=='${var.azure_devops_app_object_id}'"
}

# -----------------------------------------------------------------------
# Allow the federated identity to impersonate the terraform-pipeline SA.
# Bound to the exact subject (this specific service connection), not a
# pool-wide wildcard.
# -----------------------------------------------------------------------
resource "google_service_account_iam_member" "pipeline_impersonation" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.pipeline_service_account_email}"
  role                = "roles/iam.workloadIdentityUser"
  member              = "principal://iam.googleapis.com/${google_iam_workload_identity_pool.azure_devops.name}/subject/${var.azure_devops_subject}"
}
