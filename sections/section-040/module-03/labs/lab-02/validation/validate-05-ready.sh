#!/usr/bin/env bash
set -uo pipefail
fail=0
te() { kubectl -n outpost get teamenvironment drifter -o jsonpath="$1" 2>/dev/null; }

for condition in Ready Synced; do
  status=$(te "{.status.conditions[?(@.type==\"$condition\")].status}")
  if [ "$status" = "True" ]; then
    echo "PASS: the TeamEnvironment condition $condition is True"
  else
    echo "FAIL: the TeamEnvironment condition $condition is '$status', expected True"; fail=1
  fi
done

available=$(kubectl -n outpost get deployment scout -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "${available:-0}" -ge 1 ] 2>/dev/null; then
  echo "PASS: the Deployment scout has an available pod"
else
  echo "FAIL: the Deployment scout has no available pod"; fail=1
fi
exit $fail
