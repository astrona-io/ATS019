#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`.
# Starts the controller again. Keep in step with solution.md.
set -euo pipefail

kubectl -n default scale deployment prometheus-operator --replicas=1
kubectl -n default rollout status deployment prometheus-operator --timeout=180s
