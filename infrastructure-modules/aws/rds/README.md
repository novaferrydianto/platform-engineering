# aws/rds

Encrypted, private, multi-AZ PostgreSQL or MySQL instance.

## Security defaults

- **No password in state** — `manage_master_user_password = true` has AWS
  generate and rotate the master credential directly into Secrets Manager. The
  module exposes only the secret ARN.
- **Deny-all network access** — the security group has no ingress until
  `allowed_security_group_ids` names a caller, and no egress rules at all.
- **`publicly_accessible = false`**, private subnets only.
- **TLS enforced** at the engine (`rds.force_ssl` / `require_secure_transport`).
- **Encrypted storage, backups, and Performance Insights** with a dedicated
  auto-rotating KMS key.
- **IAM database authentication** enabled, so applications can use short-lived
  IAM tokens instead of the master password.
- **Deletion protection** and a mandatory final snapshot are on by default;
  backups retained 30 days, with 7 the enforced minimum.

## Usage

```hcl
module "database" {
  source = "../../infrastructure-modules/aws/rds"

  name               = "orders-prod"
  database_name      = "orders"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  allowed_security_group_ids = [module.eks.node_security_group_id]

  tags = { Environment = "prod" }
}
```

## Retrieving credentials

```bash
aws secretsmanager get-secret-value --secret-id "$(tofu output -raw master_user_secret_arn)"
```

Applications should prefer IAM authentication over the master credential; the
master account is for administrative access only.
