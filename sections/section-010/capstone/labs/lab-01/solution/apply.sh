#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`.
# Replaces the weak Database CRD with the two-version CRD. Keep in step with solution.md.
set -euo pipefail
cd "$(dirname "$0")"

kubectl apply -f solution.yaml
kubectl wait --for=condition=Established --timeout=60s crd/databases.platform.starfleet.io
