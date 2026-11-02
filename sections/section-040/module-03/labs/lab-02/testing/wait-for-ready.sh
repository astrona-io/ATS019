#!/usr/bin/env bash
# Helper for `astrona test`: waits until the request that the reference
# solution committed has been delivered and built.
set -euo pipefail

for i in $(seq 1 60); do
  kubectl -n outpost get teamenvironment drifter >/dev/null 2>&1 && break
  kubectl -n argocd annotate application outpost-requests \
    argocd.argoproj.io/refresh=hard --overwrite >/dev/null 2>&1 || true
  sleep 5
done
kubectl -n outpost wait teamenvironment/drifter --for=condition=Ready --timeout=300s
kubectl -n outpost rollout status deployment/scout --timeout=120s
