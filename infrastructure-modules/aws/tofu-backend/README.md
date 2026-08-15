# aws/tofu-backend

Creates the S3 bucket that holds OpenTofu remote state. This is the one module
that must be applied **before** `provisioning/live/` can run at all, because
`root.hcl` writes every unit's backend into this bucket.

No DynamoDB table: `root.hcl` sets `use_lockfile = true`, so locking uses S3
natively (OpenTofu 1.10+). A lock table would be an unused resource.

## Security defaults

- **Dedicated auto-rotating KMS key.** State contains every value the
  configuration produced, including ones marked `sensitive`.
- **Versioning on**, with expiry of superseded versions after 90 days (minimum
  30, enforced by variable validation). Versioning is the only thing that makes
  a truncated or corrupted state recoverable.
- **All four public access blocks** set, plus `BucketOwnerEnforced` ownership.
- **Bucket policy denies non-TLS access** — a state read over plaintext HTTP
  would expose everything the state holds — and denies unencrypted uploads.
- **`prevent_destroy = true`.** Losing this bucket means losing the record of
  every resource the platform manages.

## Usage

Applied through [`provisioning/bootstrap/aws`](../../../provisioning/bootstrap/aws/),
not from `provisioning/live/` — see that directory for the two-phase
local-state-then-migrate procedure.

```hcl
module "tofu_backend" {
  source = "../../infrastructure-modules/aws/tofu-backend"

  bucket_name = "my-platform-tofu-state"
  tags        = { Environment = "shared" }
}
```

The `backend_block` output prints a ready-to-paste backend configuration for
the bucket it just created.
