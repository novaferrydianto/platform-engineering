# gcp/tofu-backend

Creates the GCS bucket that holds OpenTofu remote state. Applied **before**
`provisioning/live/gcp/` can run, because `root.hcl` writes every unit's backend
into this bucket.

GCS handles state locking natively, so there is no separate lock resource.

## Security defaults

- **Uniform bucket-level access** — removes per-object ACLs so bucket IAM is the
  single place access is decided, rather than one of two.
- **`public_access_prevention = "enforced"`** — cannot be made public even by a
  later IAM mistake.
- **Versioning on**, with expiry of superseded versions after 90 days (minimum
  30, enforced by variable validation).
- **CMEK optional** via `kms_key_name`; Google-managed encryption otherwise,
  which is still encrypted at rest.
- **`prevent_destroy = true`** on the bucket.

## Usage

Applied through [`provisioning/bootstrap/gcp`](../../../provisioning/bootstrap/gcp/) —
see that directory for the two-phase local-state-then-migrate procedure.

```hcl
module "tofu_backend" {
  source = "../../infrastructure-modules/gcp/tofu-backend"

  bucket_name = "my-platform-tofu-state"
  project_id  = "my-platform-shared"
  location    = "ASIA"
}
```
