#!/usr/bin/env bash
# Installs Crossplane 2.4.2 from the rendered manifest next to this folder, then installs
# provider-kubernetes 1.4.1 with a fixed ServiceAccount name and waits until it is healthy
# and its namespaced CRDs exist. The ProviderConfig, the Object and the faulty Role are
# applied afterwards by bootstrap.manifests.
set -euo pipefail
cd "$(dirname "$0")/.."

kubectl create namespace crossplane-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace starfleet --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace outpost --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f manifests/crossplane-2.4.2.yaml >/dev/null
kubectl -n crossplane-system rollout status deployment/crossplane --timeout=300s
kubectl -n crossplane-system rollout status deployment/crossplane-rbac-manager --timeout=300s

wait_for_crd() {
  local crd="$1"
  for _ in $(seq 1 60); do
    kubectl get crd "$crd" >/dev/null 2>&1 && break
    sleep 5
  done
  kubectl wait --for=condition=Established --timeout=120s "crd/$crd"
}

for crd in providers.pkg.crossplane.io providerrevisions.pkg.crossplane.io deploymentruntimeconfigs.pkg.crossplane.io; do
  wait_for_crd "$crd"
done

kubectl apply -f manifests/provider-kubernetes.yaml >/dev/null
kubectl wait provider.pkg.crossplane.io/provider-kubernetes --for=condition=Healthy --timeout=420s
for crd in objects.kubernetes.m.crossplane.io providerconfigs.kubernetes.m.crossplane.io; do
  wait_for_crd "$crd"
done
