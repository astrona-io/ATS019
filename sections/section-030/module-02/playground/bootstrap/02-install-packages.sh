#!/usr/bin/env bash
# Installs provider-kubernetes 1.4.1 and function-patch-and-transform 0.11.0,
# waits until both are healthy, then creates the ClusterProviderConfig and
# the RBAC the provider needs. The packages are pulled from xpkg.crossplane.io.
set -euo pipefail
cd "$(dirname "$0")/.."

kubectl apply -f manifests/packages.yaml >/dev/null
kubectl wait provider.pkg.crossplane.io/provider-kubernetes --for=condition=Healthy --timeout=420s
kubectl wait function.pkg.crossplane.io/function-patch-and-transform --for=condition=Healthy --timeout=420s
for i in $(seq 1 60); do
  kubectl get crd clusterproviderconfigs.kubernetes.m.crossplane.io objects.kubernetes.m.crossplane.io >/dev/null 2>&1 && break
  sleep 5
done
kubectl wait --for=condition=Established --timeout=120s \
  crd/clusterproviderconfigs.kubernetes.m.crossplane.io crd/objects.kubernetes.m.crossplane.io
kubectl apply -f manifests/platform-access.yaml >/dev/null
