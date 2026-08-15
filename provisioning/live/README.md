# Environment stacks (Terragrunt + OpenTofu)

Where state lives and where `infrastructure-modules/` get composed with
environment-specific values. Modules stay pure and reusable; everything
environment-shaped is here.

Pinned versions: **OpenTofu 1.12.5**, **Terragrunt 1.1.3** (see
`.github/actions/setup-opentofu/action.yml`).

## Layout

```
live/
├── root.hcl                  # remote state + provider generation, inherited by every unit
├── aws/
│   ├── account.hcl           # cloud, region, state bucket, common tags
│   ├── dev/
│   │   ├── env.hcl           # CIDRs, sizes, per-environment knobs
│   │   ├── vpc/terragrunt.hcl
│   │   └── eks/terragrunt.hcl
│   ├── staging/…
│   └── prod/…                # vpc, eks, database
└── gcp/
    ├── account.hcl
    └── dev/{vpc,gke}/
```

A **unit** is a directory with a `terragrunt.hcl`. Units declare dependencies on
each other (`dependency "vpc"`), and Terragrunt orders the runs.

## Bootstrap the state backend first

State must exist before the first run — a stack cannot hold its own backend.
That bucket is **itself managed as code**, in
[`provisioning/bootstrap/`](../bootstrap/), rather than created by hand: a
bucket built with one-off CLI commands has no record of how it was configured
and drifts silently.

```bash
cd provisioning/bootstrap/aws     # or gcp
tofu init
tofu apply -var 'bucket_name=<your-globally-unique-bucket>'
```

Then migrate the bootstrap root's own state into that bucket and set
`state_bucket` in the relevant `account.hcl` — full procedure in
[`provisioning/bootstrap/README.md`](../bootstrap/README.md).

`account.hcl` ships with `REPLACE_WITH_STATE_BUCKET` on purpose. Run
`scripts/check-placeholders.sh` to confirm nothing is left unset before an
apply; a plausible-looking placeholder would otherwise fail much later with a
confusing "bucket does not exist".

## Running

```bash
cd provisioning/live/aws/dev
terragrunt run --all -- plan     # every unit, dependency-ordered
cd vpc && terragrunt run -- apply  # one unit
```

In CI this is driven by `.github/workflows/reusable-tofu-plan-apply.yml`: plan on
every PR with the diff posted as a comment, apply only on the default branch,
and **every environment — dev, staging and prod — pauses for manual approval**
via a GitHub Environment with required reviewers before anything is applied.

## Conventions

- **State is never local.** `root.hcl` generates `backend.tf` into every unit.
- **Providers are generated, not committed.** `root.hcl` writes `provider.tf`
  from the cloud named in `account.hcl`.
- **Environment values live in `env.hcl`,** not in unit files, so a unit reads
  the same in dev and prod.
- **Mock outputs** on dependencies keep `plan` working before the dependency
  exists — they are restricted to `validate` and `plan`, never `apply`.
- **Staging mirrors prod's topology.** Cost trade-offs like
  `single_nat_gateway` belong in dev only.

## Adding an environment

1. Copy the closest `env.hcl` and adjust CIDRs — they must not overlap with
   existing environments.
2. Copy the unit directories you need; they read from `env.hcl`, so most need no
   edits.
3. Create a matching GitHub Environment with **required reviewers** — this
   applies to every environment, not just prod (see `SECURITY.md` for the
   `gh api` commands).
4. Open a PR — CI plans it. Merging applies it.
