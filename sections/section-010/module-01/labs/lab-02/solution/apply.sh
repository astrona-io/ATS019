#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`.
# Adds the CEL rules, the printer columns, the short name and the category. Keep in step with solution.md.
set -euo pipefail
cd "$(dirname "$0")"

kubectl apply -f solution.yaml
kubectl wait --for=condition=Established --timeout=60s \
  crd/teamenvironments.platform.starfleet.io
