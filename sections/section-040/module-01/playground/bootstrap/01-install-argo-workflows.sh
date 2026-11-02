#!/usr/bin/env bash
# Installs Argo Workflows 4.1.5 from its release manifest and, as a
# convenience, the matching `argo` command-line tool.
# The manifest holds large CRDs, so it is applied server side.
# astrona runs this script with KUBECONFIG pointed at the playground cluster.
set -euo pipefail

VERSION=v4.1.5
RELEASE_URL="https://github.com/argoproj/argo-workflows/releases/download/${VERSION}"
mkdir -p "${HOME}/.astrona/bin"
WORK_DIR="$(mktemp -d "${HOME}/.astrona/ats019-argo.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "==> Installing Argo Workflows ${VERSION} in the namespace argo"
kubectl create namespace argo --dry-run=client -o yaml | kubectl apply -f - >/dev/null
curl -sSfL -o "$WORK_DIR/install.yaml" "${RELEASE_URL}/install.yaml"
kubectl apply --server-side -f "$WORK_DIR/install.yaml" >/dev/null
kubectl wait --for=condition=Established --timeout=120s \
  crd/workflows.argoproj.io crd/workflowtemplates.argoproj.io crd/workflowtaskresults.argoproj.io
kubectl -n argo rollout status deployment/workflow-controller --timeout=240s
kubectl -n argo rollout status deployment/argo-server --timeout=240s

# The argo CLI is optional. Every step in the course also works with kubectl,
# so a failed download only prints a warning.
echo "==> Installing the argo command-line tool in ${HOME}/.astrona/bin"
case "$(uname -s)" in
  Linux) os=linux ;;
  Darwin) os=darwin ;;
  *) os="" ;;
esac
case "$(uname -m)" in
  x86_64|amd64) arch=amd64 ;;
  aarch64|arm64) arch=arm64 ;;
  *) arch="" ;;
esac
if [ -n "$os" ] && [ -n "$arch" ] \
  && curl -sSfL -o "$WORK_DIR/argo.gz" "${RELEASE_URL}/argo-${os}-${arch}.gz" \
  && gunzip -c "$WORK_DIR/argo.gz" > "$WORK_DIR/argo" \
  && install -m 0755 "$WORK_DIR/argo" "${HOME}/.astrona/bin/argo"; then
  echo "    argo installed: ${HOME}/.astrona/bin/argo"
else
  echo "WARNING: could not install the argo command-line tool. Use kubectl instead."
fi
