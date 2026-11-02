#!/usr/bin/env bash
# Test helper: waits until the Provider reports Healthy and its CRDs exist.
set -euo pipefail

kubectl wait provider.pkg.crossplane.io/provider-kubernetes --for=condition=Healthy --timeout=420s
kubectl wait --for=condition=Established --timeout=120s crd/objects.kubernetes.m.crossplane.io
