#!/usr/bin/env bash
# Helper for `astrona test`: after the reference solution is applied, waits
# until the request is Synced and Ready and the Deployment has two replicas
# available, so the grader does not run too early.
set -euo pipefail
for i in $(seq 1 60); do
  SYNCED="$(kubectl -n outpost get teamenvironment outpost-env -o jsonpath='{.status.conditions[?(@.type=="Synced")].status}' 2>/dev/null || true)"
  READY="$(kubectl -n outpost get teamenvironment outpost-env -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)"
  AVAILABLE="$(kubectl -n outpost get deployment scout -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)"
  if [ "$SYNCED" = "True" ] && [ "$READY" = "True" ] && [ "$AVAILABLE" = "2" ]; then
    exit 0
  fi
  sleep 5
done
echo "request did not converge in 300 seconds" >&2
exit 1
