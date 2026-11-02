#!/usr/bin/env bash
# Helper for `astrona test`: after the reference solution is applied, waits until the
# request is Synced and Ready and two replicas are available, so the grader does not run
# too early.
set -euo pipefail
for _ in $(seq 1 90); do
  synced="$(kubectl -n outpost get teamenvironment scout-env -o jsonpath='{.status.conditions[?(@.type=="Synced")].status}' 2>/dev/null || true)"
  ready="$(kubectl -n outpost get teamenvironment scout-env -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)"
  available="$(kubectl -n outpost get deployment scout -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)"
  if [ "$synced" = "True" ] && [ "$ready" = "True" ] && [ "$available" = "2" ]; then
    exit 0
  fi
  sleep 5
done
echo "scout-env did not converge in 450 seconds" >&2
exit 1
