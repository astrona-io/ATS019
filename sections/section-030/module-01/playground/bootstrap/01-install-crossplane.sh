#!/usr/bin/env bash
# Installs Crossplane 2.4.2 from the rendered manifest next to this folder,
# then waits until Crossplane has created its package manager CRDs.
set -euo pipefail
cd "$(dirname "$0")/.."

kubectl create namespace crossplane-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace starfleet --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace outpost --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f manifests/crossplane-2.4.2.yaml >/dev/null
kubectl -n crossplane-system rollout status deployment/crossplane --timeout=300s
kubectl -n crossplane-system rollout status deployment/crossplane-rbac-manager --timeout=300s
for crd in providers.pkg.crossplane.io providerrevisions.pkg.crossplane.io deploymentruntimeconfigs.pkg.crossplane.io; do
  for i in $(seq 1 60); do
    kubectl get crd "$crd" >/dev/null 2>&1 && break
    sleep 5
  done
  kubectl wait --for=condition=Established --timeout=120s "crd/$crd"
done
