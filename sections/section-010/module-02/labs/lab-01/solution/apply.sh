#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`.
# Adds v1 as the storage version, deprecates v1alpha1, and creates gamma through v1.
# Keep in step with solution.md.
set -euo pipefail
cd "$(dirname "$0")"

kubectl apply -f solution.yaml
kubectl wait --for=condition=Established --timeout=60s crd/teamenvironments.platform.starfleet.io

# The v1 endpoint can take a few seconds to appear after the CRD changes.
for _ in $(seq 1 30); do
  kubectl apply -f gamma.yaml && break
  sleep 2
done
