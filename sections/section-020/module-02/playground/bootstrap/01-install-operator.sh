#!/usr/bin/env bash
# Installs the Prometheus Operator from its release bundle. The bundle holds
# large CRDs, so it is applied server side.
set -euo pipefail

VERSION=v0.94.1
curl -sSfL -o /tmp/prometheus-operator-bundle.yaml \
  "https://github.com/prometheus-operator/prometheus-operator/releases/download/${VERSION}/bundle.yaml"
kubectl apply --server-side -f /tmp/prometheus-operator-bundle.yaml >/dev/null
kubectl wait --for=condition=Established --timeout=120s \
  crd/prometheuses.monitoring.coreos.com crd/servicemonitors.monitoring.coreos.com
kubectl -n default rollout status deployment/prometheus-operator --timeout=180s
