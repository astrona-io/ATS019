#!/usr/bin/env bash
# Rejects a wildcard verb list and a Role that is wider than the task asks.
set -uo pipefail
TENANT=(--as outpost-dev --as-group outpost-team)
fail=0

for verb in update patch delete deletecollection; do
  answer=$(kubectl auth can-i "$verb" teamenvironments.platform.starfleet.io -n outpost "${TENANT[@]}" 2>/dev/null)
  if [ "$answer" = "no" ]; then
    echo "PASS: outpost-team cannot $verb teamenvironments"
  else
    echo "FAIL: outpost-team can $verb teamenvironments (only create, get, list, watch are allowed)"; fail=1
  fi
done
exit $fail
