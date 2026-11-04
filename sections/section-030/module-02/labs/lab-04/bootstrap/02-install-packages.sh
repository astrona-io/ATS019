#!/usr/bin/env bash
# Native resources need Crossplane permissions, not a provider-kubernetes wrapper.
set -euo pipefail
cd "$(dirname "$0")/.."
kubectl apply -f manifests/packages.yaml
kubectl wait function.pkg.crossplane.io/function-patch-and-transform --for=condition=Healthy --timeout=420s
kubectl apply -f manifests/platform-access.yaml
# Wait for Kubernetes to aggregate the StatefulSet permission into Crossplane's role.
for attempt in $(seq 1 60); do
  if kubectl auth can-i create statefulsets.apps --as=system:serviceaccount:crossplane-system:crossplane -n outpost | grep -qx yes; then
    exit 0
  fi
  sleep 2
done
echo 'Crossplane cannot create StatefulSets' >&2
exit 1
