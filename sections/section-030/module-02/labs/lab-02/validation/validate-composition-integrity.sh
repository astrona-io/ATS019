#!/usr/bin/env bash
# Check: the fix lives in the Composition. The original request is still in
# use, still points at the Composition teamenvironment, and still owns two
# composed Objects.
set -uo pipefail
fail() { echo "FAIL: $1"; exit 1; }
XR=(kubectl -n outpost get teamenvironment outpost-env)

"${XR[@]}" >/dev/null 2>&1 || fail "TeamEnvironment outpost-env does not exist in outpost"

SAVED_UID="$(kubectl -n starfleet get configmap lab-state -o jsonpath='{.data.xr-uid}' 2>/dev/null)"
CURRENT_UID="$("${XR[@]}" -o jsonpath='{.metadata.uid}')"
[ -n "$SAVED_UID" ] && [ "$SAVED_UID" = "$CURRENT_UID" ] \
  || fail "outpost-env was deleted and created again; repair the Composition instead"

[ "$(kubectl get composition teamenvironment -o jsonpath='{.spec.mode}' 2>/dev/null)" = "Pipeline" ] \
  || fail "Composition teamenvironment is missing or not in Pipeline mode"
[ "$(kubectl get composition teamenvironment -o jsonpath='{.spec.pipeline[0].functionRef.name}' 2>/dev/null)" = "function-patch-and-transform" ] \
  || fail "the pipeline step does not use function-patch-and-transform"

REF="$("${XR[@]}" -o jsonpath='{.spec.crossplane.compositionRef.name}')"
[ "$REF" = "teamenvironment" ] || fail "outpost-env uses Composition '$REF', expected teamenvironment"

SYNCED="$("${XR[@]}" -o jsonpath='{.status.conditions[?(@.type=="Synced")].status}')"
[ "$SYNCED" = "True" ] || fail "outpost-env is not Synced (status '$SYNCED')"

OBJECTS="$(kubectl -n outpost get objects.kubernetes.m.crossplane.io -o name 2>/dev/null | wc -l | tr -d ' ')"
[ "$OBJECTS" -ge 2 ] || fail "expected at least two composed Objects in outpost, found $OBJECTS"

echo "PASS: outpost-env still uses Composition teamenvironment and owns $OBJECTS composed Objects"
