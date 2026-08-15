# gcp/cloud-sql

Private, regional Cloud SQL instance with automated backups and PITR.

## Security defaults

- **Private IP only** — `ipv4_enabled = false`; the instance has no public
  address.
- **`ssl_mode = ENCRYPTED_ONLY`** rejects unencrypted connections.
- **Regional availability** (cross-zone standby) by default.
- **Backups with point-in-time recovery**, 30 retained, minimum 7 enforced by
  variable validation.
- **Deletion protection** on.
- **Query Insights** without recording client addresses or application tags, so
  telemetry does not become a PII sink.
- The admin password is generated in-module and written to **Secret Manager**;
  it is never an output. Applications should connect through the Cloud SQL Auth
  Proxy with IAM rather than using it.

## Prerequisite

Private IP requires a VPC peering range for service networking in the target
network before this module runs:

```bash
gcloud compute addresses create google-managed-services \
  --global --purpose=VPC_PEERING --prefix-length=16 --network=<network>
gcloud services vpc-peerings connect \
  --service=servicenetworking.googleapis.com \
  --ranges=google-managed-services --network=<network>
```

## Usage

```hcl
module "database" {
  source = "../../infrastructure-modules/gcp/cloud-sql"

  name          = "orders-prod"
  project_id    = "acme-platform-prod"
  region        = "asia-southeast1"
  database_name = "orders"
  network_id    = module.vpc.network_id

  labels = { environment = "prod" }
}
```

## State handling

The generated password lives in OpenTofu state. Keep remote state encrypted and
access-restricted — see `provisioning/live/README.md` for the backend
configuration this repo expects.
