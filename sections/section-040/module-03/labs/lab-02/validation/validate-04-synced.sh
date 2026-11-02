#!/usr/bin/env bash
set -uo pipefail
fail=0
value() { kubectl -n argocd get application outpost-requests -o jsonpath="$1" 2>/dev/null; }

sync=$(value '{.status.sync.status}')
health=$(value '{.status.health.status}')
if [ "$sync" = "Synced" ]; then
  echo "PASS: the Application is Synced"
else
  echo "FAIL: the Application sync status is '$sync', expected Synced"; fail=1
fi
if [ "$health" = "Healthy" ]; then
  echo "PASS: the Application is Healthy"
else
  echo "FAIL: the Application health is '$health', expected Healthy"; fail=1
fi
exit $fail
