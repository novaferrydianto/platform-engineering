#!/usr/bin/env bash
# Local Kubernetes cluster with Cilium as CNI, for testing this platform's
# NetworkPolicy manifests (golden path Helm charts, infrastructure-modules/
# kubernetes/namespace's default-deny) against a real policy engine.
#
# kind's default CNI (kindnet) does not enforce NetworkPolicy — objects apply
# but silently do nothing, which would hide bugs instead of catching them.
# Cilium is installed in kind's default CNI's place, matching the enforcement
# this platform's cloud modules use in production (EKS: VPC CNI native policy,
# GKE: Calico, AKS: Cilium).
#
# Requires: kind, cilium CLI, podman (both installed by scripts/vm/provision.sh).
set -euo pipefail

CLUSTER_NAME="${1:-platform-engineering}"

log() { printf '\n==> %s\n' "$1"; }

export KIND_EXPERIMENTAL_PROVIDER=podman

if kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  echo "kind cluster '${CLUSTER_NAME}' already exists — skipping create. Delete it first with:"
  echo "  kind delete cluster --name ${CLUSTER_NAME}"
else
  log "Creating kind cluster '${CLUSTER_NAME}' (default CNI disabled — Cilium takes over)"
  cat <<EOF | kind create cluster --name "$CLUSTER_NAME" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  disableDefaultCNI: true
  podSubnet: "10.244.0.0/16"
nodes:
  - role: control-plane
  - role: worker
EOF
fi

log "Installing Cilium"
cilium install --set kubeProxyReplacement=true --context "kind-${CLUSTER_NAME}"

log "Waiting for Cilium to become ready (this can take a couple of minutes)"
cilium status --wait --context "kind-${CLUSTER_NAME}"

cat <<EOF

Cluster ready: kind-${CLUSTER_NAME}

Try it against a golden path chart, e.g.:
  helm install demo golden-paths/go-service/skeleton/helm --set image.repository=... \\
    --kube-context kind-${CLUSTER_NAME}

Verify enforcement (not just presence) with:
  cilium connectivity test --context kind-${CLUSTER_NAME}

Tear down when done:
  kind delete cluster --name ${CLUSTER_NAME}
EOF
