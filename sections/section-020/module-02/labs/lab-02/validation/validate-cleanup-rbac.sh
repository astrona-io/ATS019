#!/usr/bin/env bash
# Grades the permissions of the worker: exactly what the cleanup needs on the two named
# ConfigMaps, and nothing wider.
set -u

NS="starfleet"
SA="system:serviceaccount:starfleet:probe-cleanup"
fail() { echo "FAIL: $*"; exit 1; }
can() { kubectl auth can-i "$@" --as="$SA" 2>/dev/null; }

[[ "$(can delete configmap/probe-cache -n "$NS")" == "yes" ]] || fail "the worker cannot delete the ConfigMap probe-cache"
[[ "$(can patch configmap/probe-settings -n "$NS")" == "yes" ]] || fail "the worker cannot patch the ConfigMap probe-settings"
for verb in get list watch; do
  [[ "$(can "$verb" configmap/probe-cache -n "$NS")" == "yes" ]] || fail "the worker cannot $verb probe-cache"
  [[ "$(can "$verb" configmap/probe-settings -n "$NS")" == "yes" ]] || fail "the worker cannot $verb probe-settings"
done

[[ "$(can delete configmap/probe-settings -n "$NS")" == "no" ]] || fail "the worker can delete probe-settings; it may only release the finalizer"
[[ "$(can patch configmap/probe-cache -n "$NS")" == "no" ]] || fail "the worker can patch probe-cache; it may only delete it"
[[ "$(can delete configmap/other-configmap -n "$NS")" == "no" ]] || fail "the worker can delete ConfigMaps that are not named in the cleanup"
[[ "$(can delete configmaps -n "$NS")" == "no" ]] || fail "the worker can delete every ConfigMap in $NS"
[[ "$(can delete configmap/probe-cache -n outpost)" == "no" ]] || fail "the worker can delete ConfigMaps in another namespace"
[[ "$(can delete configmaps --all-namespaces)" == "no" ]] || fail "the worker can delete ConfigMaps in all namespaces"
[[ "$(can get secrets -n "$NS")" == "no" ]] || fail "the worker can read Secrets"
[[ "$(can '*' '*')" == "no" ]] || fail "the worker can do everything (cluster-admin)"

echo "PASS: the worker may clean up probe-cache and probe-settings and nothing wider"
