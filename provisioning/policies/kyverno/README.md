# Kyverno policies

Cluster-wide admission policies. The engine is installed by
[`infrastructure-modules/kubernetes/kyverno`](../../../infrastructure-modules/kubernetes/kyverno/);
these manifests are delivered by Argo CD from
[`provisioning/gitops/applications/kyverno-policies.yaml`](../../gitops/applications/kyverno-policies.yaml),
so a policy change is a reviewed commit rather than a cluster-side edit.

## What is here, and why each one exists

| Policy | Closes |
|---|---|
| `verify-image-signatures` | The platform signs every image with cosign but nothing verified those signatures at admission. |
| `restrict-image-registries` | Pod Security Standards never inspect where an image came from. |
| `disallow-unpinned-images` | A mutable tag means the running image can drift from the reviewed one. |
| `require-resource-limits` | `LimitRange` supplies defaults; it cannot *require* a workload to declare its own. |

Deliberately **not** duplicated here: non-root, read-only root filesystem,
dropped capabilities, and privilege escalation. The `restricted` Pod Security
Standard already enforces those at the namespace
([`infrastructure-modules/kubernetes/namespace`](../../../infrastructure-modules/kubernetes/namespace/)),
and a second copy would drift.

## Before you apply these

The image references and cosign `subject` are set to `novaferrydianto`, matching
the org used by every reusable workflow and `CODEOWNERS` in this repo. **If you
fork this under a different org, change them** — in
`verify-image-signatures.yaml` and `restrict-image-registries.yaml` — or the
signature check will never match a real image and `restrict-image-registries`
will reject your own builds:

```bash
grep -rl novaferrydianto . | xargs sed -i 's|novaferrydianto|your-org|g'
```

## Rollout: Audit first, Enforce second

Every policy ships as `validationFailureAction: Audit`. Applying them in
`Enforce` against a running cluster will reject existing workloads that were
admitted before the rule existed — including, potentially, the ones that would
let you fix the problem.

```bash
# 1. Apply in Audit (the default here) and let reports accumulate
kubectl apply -f provisioning/policies/kyverno/

# 2. Read what would have been blocked
kubectl get policyreport -A
kubectl get clusterpolicyreport

# 3. Promote a policy only once its report is clean
#    (edit validationFailureAction: Enforce, commit, let Argo CD sync)
```

`verify-image-signatures` sets `failurePolicy: Fail` with
`background: false` — signature verification needs a live registry call, so a
registry outage will block admissions rather than silently admit unverified
images. That is the intended trade-off; if it is the wrong one for a given
cluster, change it deliberately rather than by accident.
