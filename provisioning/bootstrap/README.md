# Bootstrap

Creates the remote state backend. **This runs once per cloud, before anything
else in `provisioning/live/` will work.**

## The chicken-and-egg

`provisioning/live/root.hcl` writes every unit's state into a bucket. That
bucket has to exist first, and it cannot store its own state in itself before it
exists. So this root starts with **local state**, then migrates into the bucket
it just created.

That migration matters: leaving bootstrap state on one laptop means the bucket
holding all platform state is itself unmanaged and unrecoverable.

## AWS

```bash
cd provisioning/bootstrap/aws

# 1. First apply — local state, creates the bucket
tofu init
tofu apply -var 'bucket_name=my-platform-tofu-state'

# 2. Migrate this root's own state into the bucket it just made
cp backend.tf.example backend.tf     # backend.tf is gitignored by design
#    fill in the values `tofu output backend_block` printed
tofu init -migrate-state             # answer "yes" when asked to copy state

# 3. Point the live stacks at it
#    provisioning/live/aws/account.hcl → state_bucket = "my-platform-tofu-state"

# 4. Confirm a live unit can now initialise
cd ../../live/aws/dev/vpc && terragrunt init
```

After step 2, `terraform.tfstate` in this directory is a stale local copy —
delete it so nobody edits the wrong one.

## GCP

Same shape:

```bash
cd provisioning/bootstrap/gcp
tofu init
tofu apply -var 'project_id=my-platform-shared' -var 'bucket_name=my-platform-tofu-state'
cp backend.tf.example backend.tf
tofu init -migrate-state
```

## What this deliberately does not do

It does not create the AWS account, GCP project, or the OIDC trust that CI uses
to authenticate. Those are account-level concerns that belong to whoever owns
the organisation, and encoding them here would imply this repo can create its
own trust anchor — it cannot, and should not.

## Destroying

You cannot, by design: both backend modules set `prevent_destroy = true`.
Removing that guard should be a deliberate, separate, reviewed commit — losing
the bucket loses the record of every resource the platform manages.
