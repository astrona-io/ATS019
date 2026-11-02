#!/usr/bin/env bash
# Check: status.availableReplicas of the request shows the available replicas
# of the Deployment (2), written back by the Composition.
set -uo pipefail
fail() { echo "FAIL: $1"; exit 1; }

for i in $(seq 1 36); do
  STATUS="$(kubectl -n outpost get teamenvironment outpost-env -o jsonpath='{.status.availableReplicas}' 2>/dev/null)"
  AVAILABLE="$(kubectl -n outpost get deployment scout -o jsonpath='{.status.availableReplicas}' 2>/dev/null)"
  if [ -n "$STATUS" ] && [ "$STATUS" = "$AVAILABLE" ] && [ "$STATUS" = "2" ]; then
    echo "PASS: status.availableReplicas is 2 and matches Deployment scout"
    exit 0
  fi
  sleep 5
done
fail "status.availableReplicas is '$STATUS', Deployment scout reports '$AVAILABLE', expected both 2"
