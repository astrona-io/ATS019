#!/usr/bin/env bash
# Check: the Deployment follows spec.replicas of the request. The script
# reads the Deployment for the current value, changes the request to 3, waits
# for the Deployment to follow, then restores the original value. A Composition
# that hard-codes a number, or a Deployment edited by hand, fails here.
set -uo pipefail
fail() { restore; echo "FAIL: $1"; exit 1; }

XR_PATCH() { kubectl -n outpost patch teamenvironment outpost-env --type=merge -p "{\"spec\":{\"replicas\":$1}}" >/dev/null; }
deployment_replicas() { kubectl -n outpost get deployment scout -o jsonpath='{.spec.replicas}' 2>/dev/null; }
wait_for_replicas() { # value, seconds
  local i
  for i in $(seq 1 "$(( $2 / 5 ))"); do
    [ "$(deployment_replicas)" = "$1" ] && return 0
    sleep 5
  done
  return 1
}
restore() { XR_PATCH 2 2>/dev/null; }

wait_for_replicas 2 120 || fail "request asks for 2 replicas, but Deployment scout has '$(deployment_replicas)'"

XR_PATCH 3 || fail "could not change the request to 3 replicas"
wait_for_replicas 3 120 || fail "request now asks for 3 replicas, but Deployment scout has '$(deployment_replicas)'"

XR_PATCH 2
wait_for_replicas 2 120 || fail "after the request returned to 2 replicas, Deployment scout has '$(deployment_replicas)'"

echo "PASS: Deployment scout follows spec.replicas of the request (2, then 3, then 2)"
