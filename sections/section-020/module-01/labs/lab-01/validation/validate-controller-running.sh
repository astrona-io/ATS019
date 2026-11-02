#!/usr/bin/env bash
# The controller itself must run again. Editing the StatefulSet by hand does not pass this.
set -u

fail() { echo "FAIL: $*"; exit 1; }

want=$(kubectl -n default get deployment prometheus-operator -o jsonpath='{.spec.replicas}' 2>/dev/null)
[[ "${want:-0}" -ge 1 ]] || fail "the Deployment prometheus-operator in default is scaled to ${want:-0}; the controller is not running"

for _ in $(seq 1 30); do
  ready=$(kubectl -n default get deployment prometheus-operator -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  [[ "${ready:-0}" -ge 1 ]] && { echo "PASS: the Prometheus Operator controller is running"; exit 0; }
  sleep 5
done
fail "the Deployment prometheus-operator has no ready pod"
