#!/usr/bin/env bash
# Grader: the Deployment follows spec.replicas of the request. The script changes the
# request to 3, waits for the Deployment to follow, then restores 2. A Composition that
# hard-codes a number, or a Deployment edited by hand, fails here. It runs last because it
# changes the request for a short time.
set -uo pipefail

set_replicas() { kubectl -n outpost patch teamenvironment scout-env --type=merge -p "{\"spec\":{\"replicas\":$1}}" >/dev/null 2>&1; }
deployment_replicas() { kubectl -n outpost get deployment scout -o jsonpath='{.spec.replicas}' 2>/dev/null; }
wait_for_replicas() { # value, seconds
  local _
  for _ in $(seq 1 "$(( $2 / 5 ))"); do
    [ "$(deployment_replicas)" = "$1" ] && return 0
    sleep 5
  done
  return 1
}
fail() { set_replicas 2; echo "FAIL: replicas-follow-request - $1"; exit 1; }

wait_for_replicas 2 120 || fail "the request asks for 2 replicas, but Deployment scout has '$(deployment_replicas)'"
set_replicas 3 || fail "could not change the request to 3 replicas"
wait_for_replicas 3 180 || fail "the request now asks for 3 replicas, but Deployment scout has '$(deployment_replicas)'"
set_replicas 2 || fail "could not change the request back to 2 replicas"
wait_for_replicas 2 180 || fail "after the request returned to 2 replicas, Deployment scout has '$(deployment_replicas)'"

echo "PASS: replicas-follow-request - Deployment scout follows spec.replicas of the request (2, 3, 2)"
