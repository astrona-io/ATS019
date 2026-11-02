#!/usr/bin/env bash
# Grades the outcome: probe-data is the original object (same UID), has exactly one owner
# reference, to the live TeamEnvironment probe-env-v2, and the old owner probe-env is gone.
set -u

NS="outpost"
fail() { echo "FAIL: $*"; exit 1; }

baseline_uid=$(kubectl -n default get configmap lab-baseline -o jsonpath='{.data.probe_data_uid}' 2>/dev/null)
[[ -n "$baseline_uid" ]] || fail "the baseline record lab-baseline is missing; do not delete it"

kubectl -n "$NS" get teamenvironment probe-env-v2 >/dev/null 2>&1 || fail "the TeamEnvironment probe-env-v2 does not exist in $NS"
[[ "$(kubectl -n "$NS" get teamenvironment probe-env-v2 -o jsonpath='{.spec.team}' 2>/dev/null)" == "outpost" ]] || fail "probe-env-v2 must have spec.team outpost"
[[ "$(kubectl -n "$NS" get teamenvironment probe-env-v2 -o jsonpath='{.spec.size}' 2>/dev/null)" == "medium" ]] || fail "probe-env-v2 must have spec.size medium"

# The old owner can need a moment to go, so wait for it.
for _ in $(seq 1 30); do
  kubectl -n "$NS" get teamenvironment probe-env >/dev/null 2>&1 || break
  sleep 2
done
kubectl -n "$NS" get teamenvironment probe-env >/dev/null 2>&1 && fail "the old owner probe-env still exists"

uid=$(kubectl -n "$NS" get configmap probe-data -o jsonpath='{.metadata.uid}' 2>/dev/null)
[[ -n "$uid" ]] || fail "the ConfigMap probe-data is gone; it was deleted with its owner"
[[ "$uid" == "$baseline_uid" ]] || fail "probe-data was recreated (UID changed); keep the original object"
[[ "$(kubectl -n "$NS" get configmap probe-data -o jsonpath='{.data.mode}' 2>/dev/null)" == "small" ]] || fail "the data of probe-data was changed"

v2_uid=$(kubectl -n "$NS" get teamenvironment probe-env-v2 -o jsonpath='{.metadata.uid}')
owner_uids=$(kubectl -n "$NS" get configmap probe-data -o jsonpath='{.metadata.ownerReferences[*].uid}')
owner_names=$(kubectl -n "$NS" get configmap probe-data -o jsonpath='{.metadata.ownerReferences[*].name}')
owner_kinds=$(kubectl -n "$NS" get configmap probe-data -o jsonpath='{.metadata.ownerReferences[*].kind}')
[[ "$owner_uids" == "$v2_uid" ]] || fail "probe-data must have exactly one owner reference, with the UID of probe-env-v2 (found UIDs '$owner_uids')"
[[ "$owner_names" == "probe-env-v2" && "$owner_kinds" == "TeamEnvironment" ]] || fail "the owner reference must name the TeamEnvironment probe-env-v2 (found '$owner_kinds' '$owner_names')"

echo "PASS: probe-data is the original ConfigMap and is owned only by probe-env-v2; probe-env is gone"
