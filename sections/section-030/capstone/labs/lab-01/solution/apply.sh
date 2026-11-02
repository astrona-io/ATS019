#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`. Keep in step with solution.md.
# Order matters: the provider first, then its configuration, the RBAC and the platform API,
# then the tenant request.
set -euo pipefail
cd "$(dirname "$0")"

wait_for_crd() {
  for _ in $(seq 1 120); do
    kubectl get crd "$1" >/dev/null 2>&1 && return 0
    sleep 5
  done
  echo "CRD $1 did not appear" >&2
  return 1
}

kubectl apply -f provider.yaml
wait_for_crd providers.pkg.crossplane.io
kubectl wait provider.pkg.crossplane.io/provider-kubernetes --for=condition=Healthy --timeout=600s
wait_for_crd clusterproviderconfigs.kubernetes.m.crossplane.io
wait_for_crd objects.kubernetes.m.crossplane.io
kubectl wait --for=condition=Established --timeout=120s \
  crd/clusterproviderconfigs.kubernetes.m.crossplane.io crd/objects.kubernetes.m.crossplane.io

kubectl apply -f solution.yaml
kubectl wait xrd/teamenvironments.platform.starfleet.io --for=condition=Established --timeout=120s
kubectl apply -f request.yaml
