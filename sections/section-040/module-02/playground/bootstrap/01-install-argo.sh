#!/usr/bin/env bash
# Installs Argo Workflows 4.1.5 (namespace argo) and Argo Events 1.9.11
# (namespace argo-events) from their release manifests. Both bundles hold large
# CRDs, so they are applied server side. Needs outbound internet access.
set -euo pipefail

WORKFLOWS_VERSION=v4.1.5
EVENTS_VERSION=v1.9.11
BUNDLE_DIR="$(mktemp -d "${HOME}/.astrona/ats019-argo.XXXXXX")"
trap 'rm -rf "$BUNDLE_DIR"' EXIT

kubectl create namespace argo --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl create namespace argo-events --dry-run=client -o yaml | kubectl apply -f - >/dev/null

curl -sSfL -o "$BUNDLE_DIR/workflows.yaml" \
  "https://github.com/argoproj/argo-workflows/releases/download/${WORKFLOWS_VERSION}/install.yaml"
curl -sSfL -o "$BUNDLE_DIR/events.yaml" \
  "https://github.com/argoproj/argo-events/releases/download/${EVENTS_VERSION}/install.yaml"

kubectl apply --server-side --force-conflicts -f "$BUNDLE_DIR/workflows.yaml" >/dev/null
kubectl apply --server-side --force-conflicts -f "$BUNDLE_DIR/events.yaml" >/dev/null

kubectl wait --for=condition=Established --timeout=120s \
  crd/workflows.argoproj.io crd/workflowtemplates.argoproj.io \
  crd/workflowtaskresults.argoproj.io crd/eventbus.argoproj.io \
  crd/eventsources.argoproj.io crd/sensors.argoproj.io
kubectl -n argo rollout status deployment/workflow-controller --timeout=240s
kubectl -n argo-events rollout status deployment/controller-manager --timeout=240s
