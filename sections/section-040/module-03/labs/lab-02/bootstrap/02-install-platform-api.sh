#!/usr/bin/env bash
# Installs provider-kubernetes 1.4.1 and function-patch-and-transform 0.11.0,
# gives the provider the RBAC it needs in `outpost`, then applies the
# TeamEnvironment XRD and the working Composition. Crossplane must already
# run (01-install-crossplane.sh).
set -euo pipefail
cd "$(dirname "$0")/.."

kubectl apply -f manifests/platform/packages.yaml >/dev/null
kubectl wait provider.pkg.crossplane.io/provider-kubernetes \
  --for=condition=Healthy --timeout=600s
kubectl wait function.pkg.crossplane.io/function-patch-and-transform \
  --for=condition=Healthy --timeout=600s
kubectl wait --for=condition=Established --timeout=120s \
  crd/clusterproviderconfigs.kubernetes.m.crossplane.io \
  crd/objects.kubernetes.m.crossplane.io

kubectl apply -f manifests/platform/providerconfig-in-cluster.yaml >/dev/null
kubectl apply -f manifests/platform/rbac-provider-kubernetes.yaml >/dev/null
kubectl apply -f manifests/platform/xrd-teamenvironment.yaml >/dev/null
kubectl wait xrd/teamenvironments.platform.starfleet.io \
  --for=condition=Established --timeout=120s
kubectl wait --for=condition=Established --timeout=120s \
  crd/teamenvironments.platform.starfleet.io
kubectl apply -f manifests/platform/composition-teamenvironment.yaml >/dev/null
