#!/usr/bin/env bash
# Grades the outcome: scout-env is gone, the garbage collector removed its dependent scout-config,
# the ConfigMap that only shares the label is untouched, and the new owner was not removed.
set -u

NS="outpost"
fail() { echo "FAIL: $*"; exit 1; }

unowned_baseline=$(kubectl -n default get configmap lab-baseline -o jsonpath='{.data.scout_unowned_uid}' 2>/dev/null)
[[ -n "$unowned_baseline" ]] || fail "the baseline record lab-baseline is missing; do not delete it"

for _ in $(seq 1 30); do
  kubectl -n "$NS" get teamenvironment scout-env >/dev/null 2>&1 || break
  sleep 2
done
kubectl -n "$NS" get teamenvironment scout-env >/dev/null 2>&1 && fail "the TeamEnvironment scout-env still exists"

for _ in $(seq 1 30); do
  kubectl -n "$NS" get configmap scout-config >/dev/null 2>&1 || break
  sleep 2
done
kubectl -n "$NS" get configmap scout-config >/dev/null 2>&1 && fail "the dependent ConfigMap scout-config still exists after its owner was deleted"

uid=$(kubectl -n "$NS" get configmap scout-unowned -o jsonpath='{.metadata.uid}' 2>/dev/null)
[[ -n "$uid" ]] || fail "scout-unowned was deleted; a shared label is not ownership, so it must stay"
[[ "$uid" == "$unowned_baseline" ]] || fail "scout-unowned was recreated (UID changed); keep the original object"
[[ "$(kubectl -n "$NS" get configmap scout-unowned -o jsonpath='{.metadata.labels.team}' 2>/dev/null)" == "outpost" ]] || fail "scout-unowned lost its label team=outpost"

kubectl -n "$NS" get teamenvironment probe-env-v2 >/dev/null 2>&1 || fail "the new owner probe-env-v2 was deleted"

echo "PASS: scout-env and scout-config are gone, and scout-unowned and probe-env-v2 remain"
