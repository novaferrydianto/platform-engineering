# Crossplane self-service

The in-cluster provisioning path. A team applies a claim and gets a real cloud
resource — no PR into `provisioning/live/`, no platform-team ticket.

## When to use which path

| | `provisioning/live/` (Terragrunt) | `provisioning/crossplane/` |
|---|---|---|
| Owns | Accounts, networks, clusters, IAM | Per-application resources (databases, buckets, queues) |
| Change flow | PR → plan → review → apply | `kubectl apply` a claim |
| Review | Human, always | Encoded in the Composition |
| Blast radius | Environment-wide | One namespace |

Foundational infrastructure keeps a human in the loop. Day-2 application
resources do not need one, because the guardrails are in the Composition rather
than in the reviewer's head.

## Structure

```
crossplane/
├── xrds/             # the API developers see (CompositeResourceDefinition)
├── compositions/     # how that API maps to real cloud resources
└── examples/         # a sample claim
```

## What actually exists today

| API | XRD | Compositions |
|---|---|---|
| `XDatabaseInstance` | ✅ | AWS only (`xdatabaseinstance-aws.yaml`) |

GCP and Azure compositions for `XDatabaseInstance` are **not written yet**, so a
claim targeting those clouds has nothing to resolve against. Object storage
(`XBucketStore`) and queues are candidates, not implementations. Treat this
directory as one worked example of the pattern rather than a complete
self-service catalogue.

## Install

```bash
kubectl apply -f xrds/
kubectl apply -f compositions/
kubectl apply -f examples/database-claim.yaml

kubectl get databaseinstance -n orders-prod
kubectl describe xdatabaseinstance
```

Requires Crossplane with `provider-aws-rds` and
`function-patch-and-transform` installed, plus a `ProviderConfig` authenticating
via IRSA — not a static access key.

## Why the claim API is deliberately small

The XRD exposes t-shirt sizes and a handful of knobs. It does **not** expose
encryption, backup retention, public accessibility, or credential handling —
those are fixed in the Composition so no claim can weaken them. Widening the API
is a platform-team decision, and every new field is a guardrail someone can now
turn off.

## Adding a new resource type

1. Write the XRD — the developer-facing API. Keep it small; prefer t-shirt sizes
   over raw cloud parameters.
2. Write a Composition per cloud, with secure defaults hard-coded rather than
   patched from the claim.
3. Add an example claim.
4. Surface it in the portal as a Backstage template that applies the claim, so
   it appears alongside the other golden paths.
