# Enables each required API on the project. Using for_each (not count) so
# that adding/removing an API in the list doesn't force-recreate unrelated
# resources — each API's enablement is tracked independently in state.
resource "google_project_service" "apis" {
  for_each = toset(var.apis_to_enable)

  project = var.project_id
  service = each.value

  # Don't disable the API on `terraform destroy` — safer default for a
  # personal project where you don't want an accidental destroy to break
  # things you're still using outside this Terraform's scope.
  disable_on_destroy = false
}
