#!/usr/bin/env bash
# Installs function-patch-and-transform 0.11.0 and waits until it is healthy, so the
# learner can write a Composition at once. The provider is NOT installed here: installing it
# is part of the task. The package is pulled from xpkg.crossplane.io.
set -euo pipefail
cd "$(dirname "$0")/.."

for i in $(seq 1 60); do
  kubectl get crd functions.pkg.crossplane.io >/dev/null 2>&1 && break
  sleep 5
done
kubectl apply -f manifests/function-patch-and-transform.yaml >/dev/null
kubectl wait function.pkg.crossplane.io/function-patch-and-transform --for=condition=Healthy --timeout=600s
