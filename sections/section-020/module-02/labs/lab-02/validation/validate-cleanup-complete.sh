#!/usr/bin/env bash
# Grades the outcome: the worker Job ran to completion, and both ConfigMaps are gone.
# Removing the finalizer by hand makes the Job fail in its first init container, because
# probe-settings no longer exists, so a Complete Job proves the worker did the cleanup.
set -u

NS="starfleet"
fail() { echo "FAIL: $*"; exit 1; }

kubectl -n "$NS" get job probe-cleanup >/dev/null 2>&1 || fail "the Job probe-cleanup does not exist in $NS"

# A failed pod is retried with a growing delay, so wait for the condition.
complete=""
for _ in $(seq 1 36); do
  complete=$(kubectl -n "$NS" get job probe-cleanup -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}' 2>/dev/null)
  [[ "$complete" == "True" ]] && break
  sleep 5
done
if [[ "$complete" != "True" ]]; then
  suspended=$(kubectl -n "$NS" get job probe-cleanup -o jsonpath='{.spec.suspend}' 2>/dev/null)
  if [[ "$suspended" == "true" ]]; then
    fail "the Job probe-cleanup is still suspended, so no worker runs"
  fi
  fail "the Job probe-cleanup is not Complete; read the logs of its pods with --all-containers"
fi

kubectl -n "$NS" get configmap probe-cache >/dev/null 2>&1 && fail "probe-cache still exists; the worker must delete it"
kubectl -n "$NS" get configmap probe-settings >/dev/null 2>&1 && fail "probe-settings still exists; its finalizer is not released"

echo "PASS: the cleanup Job is Complete and both ConfigMaps are gone"
