# gcp-devops-pipeline

A personal learning project: GCP infrastructure managed via Terraform, deployed through an
Azure DevOps pipeline, authenticated with zero stored keys via Workload Identity Federation.

## Structure

```
terraform/
  bootstrap/   # State bucket + pipeline SA + its project-level roles. Local-apply ONLY.
  wif/         # Workload Identity Pool/Provider + impersonation grant. Local-apply ONLY.
  project/     # API enablement. Safe to run through the pipeline.
pipelines/
  azure-pipelines.yml
```

`bootstrap` and `wif` are deliberately **never** run through the pipeline itself — they define
the trust relationship the pipeline depends on to authenticate at all. If the pipeline broke
its own credentials mid-apply, there'd be no way to use the pipeline to fix it. `project` (and
future modules like `network`, `compute`) are safe for the pipeline to manage.

## Workload Identity Federation: Azure DevOps → GCP

### Which flow are you actually on?

Azure DevOps has **two different, mutually exclusive** federation flows depending on how the
service connection was set up. Don't assume — always check the connection's Overview tab
("Workload Identity federation details") directly.

| | Legacy (Azure DevOps-issued) | Entra-issued (what this repo uses) |
|---|---|---|
| Issuer | `https://vstoken.dev.azure.com/<org-GUID>` | `https://login.microsoftonline.com/<tenant-GUID>/v2.0` |
| Subject format | `sc://<org>/<project>/<connection>` (short, ~46 chars) | `/eid1/c/pub/t/.../sc/<guid>/<guid>` (long, ~138 chars) |
| Audience | `api://AzureADTokenExchange` | `fb60f99c-7a34-4190-8149-302f77469936` (fixed Microsoft app ID) |
| `attribute_mapping` | `google.subject = assertion.sub` (fits under 127-char limit) | `google.subject = assertion.sub.split('/sc/')[1]` (raw sub exceeds limit) |

**Getting these values wrong produces different, specific errors** — useful for diagnosing
which one you have:
- Wrong issuer → `issuer claim in OIDC discovery document does not match the issuer specified in the request`
- Wrong audience → token validates issuer but fails at a later stage
- Wrong `attribute_condition` (oid) → `unauthorized_client / The given credential is rejected by the attribute condition`
- Wrong subject on the impersonation binding → `iam.serviceAccounts.getAccessToken denied`

### The `oid` trap

The service connection's Overview page shows **two different Object IDs** for the same app:
- "Manage App registration" → App Registration Object ID
- Entra ID → Enterprise Applications → same app → a **different** Object ID (Service Principal)

The `oid` claim in the actual token is the **Service Principal** Object ID, not the App
Registration one. We only found this by decoding the real JWT in a pipeline run and comparing
byte-for-byte — don't trust the app registration page's Object ID for `attribute_condition`.

### Subject drift

The service connection's Subject identifier can **change** if the connection is edited/re-saved
(even without deleting it) — the `oid` stays stable (tied to the app registration) but the
subject can regenerate. If a previously-working setup starts failing with
`iam.serviceAccounts.getAccessToken denied` again, re-copy the *live* Subject identifier from
the portal rather than trusting an old screenshot or a value copied days earlier.

### Roles actually required on `terraform-pipeline`

Confirmed by direct testing, not just documentation:

| Role | Scope | Why |
|---|---|---|
| `roles/storage.objectAdmin` | State bucket only | Read/write Terraform state |
| `roles/iam.workloadIdentityUser` | On the SA itself, pinned to exact subject | Lets the federated identity impersonate this SA |
| `roles/serviceusage.serviceUsageAdmin` | Project | Enable/disable APIs |
| `roles/servicemanagement.admin` | Project | **Also required** — `serviceUsageAdmin` alone was NOT sufficient for `google_project_service` to succeed in practice, even though Policy Troubleshooter showed the permission as granted. This one actually resolved it. |

### Debugging technique that actually worked

Guessing from error text alone repeatedly led to wrong fixes. What worked:
1. **Decode the actual JWT** in the pipeline (see the debug block pattern in `azure-pipelines.yml` history) — print `iss`, `aud`, `sub`, `oid` directly rather than trusting portal screenshots.
2. **Cloud Logging audit entries** (`protoPayload.authenticationInfo.principalSubject` / `principalEmail`) show exactly what identity GCP evaluated for a specific denied call — compare byte-for-byte against the configured IAM binding.
3. **Policy Troubleshooter** (manual mode: principal + resource + permission) confirms current access directly — but note its own disclaimer that it shows *current* state, which may differ from the state at the time of an earlier failure (propagation delay).
4. **`gcloud ... get-iam-policy`** for ground truth on what's actually bound, independent of the Terraform state or console UI caching.

### Pipeline hygiene

Always run `terraform init`/`plan`/`apply` with `-input=false` in CI. Without it, a missing
required variable causes Terraform to silently wait on an interactive prompt that can never be
answered — this produced a 17-minute "hang" that looked like a network issue but was actually
just an unanswered prompt.
