#!/usr/bin/env bash
# Grades the owner references. Each environment ConfigMap must point at the TeamEnvironment
# scout-env with its real, current UID. A reference with a wrong UID would make the garbage
# collector delete the ConfigMap, so existence is checked too. This rejects: a label as
# "ownership", a reference by name with a made-up UID, owning the shared ConfigMap, and
# deleting and recreating the TeamEnvironment.
set -u

NS="outpost"
fail() { echo "FAIL: $*"; exit 1; }

env_uid=$(kubectl -n "$NS" get teamenvironment scout-env -o jsonpath='{.metadata.uid}' 2>/dev/null)
[[ -n "$env_uid" ]] || fail "the TeamEnvironment scout-env does not exist in $NS"
baseline_uid=$(kubectl -n kube-system get configmap ats019-capstone-baseline -o jsonpath='{.data.teamEnvironmentUID}' 2>/dev/null)
[[ "$env_uid" == "$baseline_uid" ]] || fail "scout-env was deleted and created again; add the references to the original object"

# The garbage collector needs a moment to act on a wrong reference, so wait before reading.
sleep 10

for name in scout-env-settings scout-env-limits; do
  kubectl -n "$NS" get configmap "$name" >/dev/null 2>&1 || fail "the ConfigMap $name no longer exists (a reference to an owner that does not exist makes the garbage collector delete it)"
  refs=$(kubectl -n "$NS" get configmap "$name" -o jsonpath='{range .metadata.ownerReferences[*]}{.apiVersion}/{.kind}/{.name}/{.uid}{"\n"}{end}')
  [[ "$refs" == "platform.starfleet.io/v1alpha1/TeamEnvironment/scout-env/$env_uid" ]] \
    || fail "the ConfigMap $name has owner references '$refs'; it needs exactly one, to platform.starfleet.io/v1alpha1 TeamEnvironment scout-env with uid $env_uid"
  [[ "$(kubectl -n "$NS" get configmap "$name" -o jsonpath='{.data.mode}')" == "small" ]] || fail "the data of $name was changed"
done

kubectl -n "$NS" get configmap shared-notes >/dev/null 2>&1 || fail "the ConfigMap shared-notes was deleted"
shared_refs=$(kubectl -n "$NS" get configmap shared-notes -o jsonpath='{.metadata.ownerReferences}' 2>/dev/null)
[[ -z "$shared_refs" ]] || fail "shared-notes has an owner reference; it does not belong to scout-env, so a shared label is not a reason to own it"

echo "PASS: scout-env-settings and scout-env-limits are owned by scout-env, and shared-notes is not"
