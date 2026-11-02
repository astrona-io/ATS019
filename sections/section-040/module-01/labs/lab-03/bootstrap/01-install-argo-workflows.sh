#!/usr/bin/env bash
# Installs Argo Workflows 4.1.5 from its release manifest.
# The manifest holds large CRDs, so it is applied server side.
# astrona runs this script with KUBECONFIG pointed at the lab cluster.
# The lab uses only the workflow controller, so the Argo server is scaled to
# zero to save memory.
set -euo pipefail

VERSION=v4.1.5
mkdir -p "${HOME}/.astrona"
WORK_DIR="$(mktemp -d "${HOME}/.astrona/ats019-argo.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "==> Installing Argo Workflows ${VERSION} in the namespace argo"
kubectl create namespace argo --dry-run=client -o yaml | kubectl apply -f - >/dev/null
curl -sSfL -o "$WORK_DIR/install.yaml" \
  "https://github.com/argoproj/argo-workflows/releases/download/${VERSION}/install.yaml"
kubectl apply --server-side -f "$WORK_DIR/install.yaml" >/dev/null
kubectl -n argo scale deployment/argo-server --replicas=0 >/dev/null
kubectl wait --for=condition=Established --timeout=120s \
  crd/workflows.argoproj.io crd/workflowtemplates.argoproj.io crd/workflowtaskresults.argoproj.io
kubectl -n argo rollout status deployment/workflow-controller --timeout=240s
