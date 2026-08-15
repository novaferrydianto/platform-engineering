# GitOps (Argo CD)

Argo CD is installed by
[`infrastructure-modules/kubernetes/argocd`](../../infrastructure-modules/kubernetes/argocd/).
Everything it manages is declared here, so the install is the only imperative
step and every subsequent change is a reviewed commit.

## App-of-apps

```
root-app.yaml            → watches applications/, recursively
└── applications/
    └── kyverno-policies.yaml → syncs provisioning/policies/kyverno/
```

Adding a platform component means adding one `Application` manifest to
`applications/`. The root Application picks it up on the next sync; nothing is
applied by hand.

## Bootstrap

```bash
# 1. repoURL points at novaferrydianto/platform-engineering. If you forked this
#    under a different org, change it — Argo CD reconciles against the remote
#    URL, not against whatever is checked out locally.
grep -rl novaferrydianto . | xargs sed -i 's|novaferrydianto|your-org|g'

# 2. Argo CD itself must already be installed via OpenTofu
kubectl apply -f root-app.yaml

# 3. Watch it converge
kubectl get applications -n argocd -w
```

## Why `prune` and `selfHeal` are both on

Without `prune`, deleting a manifest from git leaves the resource running in the
cluster forever. Without `selfHeal`, a manual `kubectl edit` silently persists
and git stops describing reality. Together they make git the only way to change
the cluster — which is the property that makes a GitOps repo trustworthy as an
audit record.

The trade-off is real: an emergency `kubectl` fix will be reverted within
minutes. That is intended. Emergency changes go through a PR, or through
`argocd app set --sync-policy none` first, deliberately and visibly.

## What is deliberately *not* here

Application workloads from the golden paths still deploy through
`reusable-helm-deploy.yml` in CI. See the comparison table in the
[Argo CD module README](../../infrastructure-modules/kubernetes/argocd/README.md)
for why both paths exist and when each is the right one.
