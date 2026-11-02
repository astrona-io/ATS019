#!/usr/bin/env bash
# Creates the stuck-deletion starting state. The deletion request must come after the
# ConfigMap exists, so it runs here and not in bootstrap.manifests. The ConfigMap stays
# in the API because of its finalizer.
set -euo pipefail
cd "$(dirname "$0")/.."

kubectl apply -f manifests/lab-start.yaml >/dev/null
kubectl -n starfleet delete configmap probe-settings --wait=false >/dev/null
kubectl -n starfleet get configmap probe-settings \
  -o jsonpath='{.metadata.deletionTimestamp}' | grep -q .
