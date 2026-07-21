variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "pool_id" {
  description = "ID for the workload identity pool. Cannot start with 'gcp-' (reserved by Google) and cannot be changed later."
  type        = string
  default     = "azure-devops-pool"
}

variable "provider_id" {
  description = "ID for the OIDC provider within the pool. Cannot start with 'gcp-' (reserved) and cannot be changed later."
  type        = string
  default     = "star-devops-mvp"
}

variable "azure_devops_issuer_uri" {
  description = <<-EOT
    The EXACT "Issuer" value from the service connection's Overview tab
    (Workload Identity federation details section). For an org using the
    newer Entra-issued token flow (confirmed for this environment), this
    looks like: https://login.microsoftonline.com/<tenant-GUID>/v2.0
    NOT https://vstoken.dev.azure.com/... — that's the older, different
    flow. Always copy from the actual portal screen, don't assume which
    flow applies.
  EOT
  type        = string
}

variable "azure_devops_subject" {
  description = <<-EOT
    The part of the real "Subject identifier" (from the same Overview tab)
    AFTER "/sc/". The full subject in this flow is long (~138 chars,
    format /eid1/c/pub/t/.../sc/<guid>/<guid>) and exceeds Google's
    127-char limit for google.subject, so Terraform maps only this
    trailing part via split('/sc/')[1]. Example: if the full subject ends
    in ".../sc/16d1374c-3e00-4dfd-b524-1228e863f571/73014a66-c337-4dfd-9fad-83e13a35031c",
    this variable is "16d1374c-3e00-4dfd-b524-1228e863f571/73014a66-c337-4dfd-9fad-83e13a35031c".
  EOT
  type        = string
}

variable "azure_devops_app_object_id" {
  description = "The Entra ID Object ID (NOT Application/Client ID) of the auto-created app registration behind the service connection. Restricts the trust to this specific app so no other Azure DevOps org or connection can authenticate."
  type        = string
}

variable "pipeline_service_account_email" {
  description = "Email of the terraform-pipeline service account created in the bootstrap module. The federated identity impersonates this SA rather than being granted GCP roles directly."
  type        = string
}
