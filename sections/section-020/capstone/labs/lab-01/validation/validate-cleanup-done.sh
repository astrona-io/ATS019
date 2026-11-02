#!/usr/bin/env bash
# Grades the deletion. scout-settings must be gone, scout-cache must be gone, and the
# cleanup Job must have run to completion as the ServiceAccount scout-cleanup. This rejects
# removing the finalizer by hand (the Job never completes) and deleting only scout-settings.
set -u

NS="outpost"
fail() { echo "FAIL: $*"; exit 1; }
job() { kubectl -n "$NS" get job scout-cleanup -o jsonpath="$1" 2>/dev/null; }

kubectl -n "$NS" get job scout-cleanup >/dev/null 2>&1 || fail "the Job scout-cleanup does not exist; the cleanup must run through the Job"

# The Job needs time to start its pod and run its three containers.
complete=""
for _ in $(seq 1 36); do
  complete=$(job '{.status.conditions[?(@.type=="Complete")].status}')
  [[ "$complete" == "True" ]] && break
  sleep 5
done
[[ "$complete" == "True" ]] || fail "the Job scout-cleanup is not Complete (succeeded '$(job '{.status.succeeded}')', failed '$(job '{.status.failed}')'); read its conditions and the logs of its pod"
[[ "$(job '{.spec.template.spec.serviceAccountName}')" == "scout-cleanup" ]] || fail "the Job does not run as the ServiceAccount scout-cleanup"

if kubectl -n "$NS" get configmap scout-settings >/dev/null 2>&1; then
  fail "the ConfigMap scout-settings still exists: deletionTimestamp '$(kubectl -n "$NS" get configmap scout-settings -o jsonpath='{.metadata.deletionTimestamp}')', finalizers '$(kubectl -n "$NS" get configmap scout-settings -o jsonpath='{.metadata.finalizers}')'"
fi
if kubectl -n "$NS" get configmap scout-cache >/dev/null 2>&1; then
  fail "the ConfigMap scout-cache still exists; the cleanup must delete it before it releases scout-settings"
fi
kubectl -n "$NS" get configmap shared-notes >/dev/null 2>&1 || fail "the ConfigMap shared-notes was deleted; only scout-settings and scout-cache may go"

echo "PASS: the cleanup Job completed and scout-settings and scout-cache are gone"
