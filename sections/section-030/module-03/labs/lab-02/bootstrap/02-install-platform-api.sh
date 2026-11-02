#!/usr/bin/env bash
# Installs provider-kubernetes 1.4.1 and function-patch-and-transform 0.11.0,
# connects the provider to this cluster, gives it the RBAC it needs in outpost,
# and defines the TeamEnvironment API. Packages come from xpkg.crossplane.io.
set -euo pipefail
cd "$(dirname "$0")/.."

wait_for_crd() {
  for i in $(seq 1 120); do
    kubectl get crd "$1" >/dev/null 2>&1 && return 0
    sleep 5
  done
  echo "CRD $1 did not appear" >&2
  return 1
}

kubectl apply -f manifests/provider-kubernetes.yaml >/dev/null
kubectl apply -f manifests/function-patch-and-transform.yaml >/dev/null
wait_for_crd providers.pkg.crossplane.io
kubectl wait provider.pkg.crossplane.io/provider-kubernetes --for=condition=Healthy --timeout=600s
kubectl wait function.pkg.crossplane.io/function-patch-and-transform --for=condition=Healthy --timeout=600s

wait_for_crd clusterproviderconfigs.kubernetes.m.crossplane.io
wait_for_crd objects.kubernetes.m.crossplane.io
kubectl wait --for=condition=Established --timeout=120s \
  crd/clusterproviderconfigs.kubernetes.m.crossplane.io \
  crd/objects.kubernetes.m.crossplane.io
kubectl apply -f manifests/clusterproviderconfig-in-cluster.yaml >/dev/null
kubectl apply -f manifests/rbac-provider-kubernetes.yaml >/dev/null

kubectl apply -f manifests/xrd-teamenvironment.yaml >/dev/null
kubectl wait xrd/teamenvironments.platform.starfleet.io --for=condition=Established --timeout=120s
