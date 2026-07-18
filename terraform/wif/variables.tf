variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "pool_id" {
  description = "ID for the workload identity pool. Cannot start with 'gcp-' (reserved) and cannot be changed later."
  type        = string
  default     = "azure-devops-pool"
}

variable "provider_id" {
  description = "ID for the OIDC provider within the pool. Cannot be changed later."
  type        = string
  default     = "star-devops-mvp"
}

variable "azure_devops_issuer_uri" {
  description = "The 'Issuer' value copied from the Azure DevOps service connection's Workload Identity federation details (looks like https://vstoken.dev.azure.com/<org-id>)."
  type        = string
}

variable "azure_devops_app_object_id" {
  description = "The Entra ID object ID of the auto-created app registration behind the service connection. Used in the attribute condition so ONLY this specific service connection can authenticate — without this, any Azure DevOps org's token could theoretically be crafted to match."
  type        = string
}

variable "pipeline_service_account_email" {
  description = "Email of the terraform-pipeline service account created in the bootstrap module. The federated identity will impersonate this SA rather than being granted GCP roles directly."
  type        = string
}

variable "azure_devops_subject" {
  description = "The part of the service connection's Subject identifier AFTER '/sc/'. E.g. if Subject identifier is '<prefix>/sc/gcp-terraform', enter 'gcp-terraform'. This is what google.subject resolves to after the attribute mapping, and lets us pin the impersonation grant to this exact service connection rather than any identity in the pool."
  type        = string
}
