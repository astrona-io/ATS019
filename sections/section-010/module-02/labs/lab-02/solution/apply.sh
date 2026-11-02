#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`.
# Enables the status and scale subresources, writes status as the controller would,
# and scales beta with kubectl scale. Keep in step with solution.md.
set -euo pipefail
cd "$(dirname "$0")"

kubectl apply -f solution.yaml
kubectl wait --for=condition=Established --timeout=60s crd/teamenvironments.platform.starfleet.io

retry() {
  for _ in $(seq 1 30); do
    "$@" && return 0
    sleep 2
  done
  return 1
}

retry kubectl -n outpost patch teamenvironment alpha --subresource=status --type merge \
  -p '{"status":{"readyReplicas":2,"phase":"Ready"}}'
retry kubectl -n outpost scale teamenvironment beta --replicas=4
retry kubectl -n outpost patch teamenvironment beta --subresource=status --type merge \
  -p '{"status":{"readyReplicas":4,"phase":"Ready"}}'
