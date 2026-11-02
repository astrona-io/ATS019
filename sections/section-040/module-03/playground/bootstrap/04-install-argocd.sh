#!/usr/bin/env bash
# Installs Argo CD 3.5.4 from its release install manifest. The CRDs are large,
# so the manifest is applied server side. Dex, the notifications controller and
# the ApplicationSet controller are not needed here, so they are scaled to zero
# to save memory.
set -euo pipefail

VERSION=v3.5.4
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

curl -sSfL -o "$WORK_DIR/install.yaml" \
  "https://raw.githubusercontent.com/argoproj/argo-cd/${VERSION}/manifests/install.yaml"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl apply --server-side --force-conflicts -n argocd -f "$WORK_DIR/install.yaml" >/dev/null
kubectl wait --for=condition=Established --timeout=120s \
  crd/applications.argoproj.io crd/appprojects.argoproj.io
kubectl -n argocd scale deployment/argocd-dex-server \
  deployment/argocd-notifications-controller \
  deployment/argocd-applicationset-controller --replicas=0 >/dev/null
kubectl -n argocd rollout status deployment/argocd-repo-server --timeout=300s
kubectl -n argocd rollout status deployment/argocd-server --timeout=300s
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=300s
