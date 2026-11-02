#!/usr/bin/env bash
# Check: the repair is in the Composition teamenvironment. Its pipeline names an
# installed Function, and the original request still uses it.
set -uo pipefail
fail() { echo "FAIL: $1"; exit 1; }
XR=(kubectl -n outpost get teamenvironment outpost-env)

"${XR[@]}" >/dev/null 2>&1 || fail "TeamEnvironment outpost-env does not exist in outpost"

SAVED_UID="$(kubectl -n starfleet get configmap lab-state -o jsonpath='{.data.xr-uid}' 2>/dev/null)"
CURRENT_UID="$("${XR[@]}" -o jsonpath='{.metadata.uid}')"
[ -n "$SAVED_UID" ] && [ "$SAVED_UID" = "$CURRENT_UID" ] \
  || fail "outpost-env was deleted and created again; repair the Composition instead"

kubectl get composition teamenvironment >/dev/null 2>&1 || fail "Composition teamenvironment does not exist"
[ "$(kubectl get composition teamenvironment -o jsonpath='{.spec.mode}')" = "Pipeline" ] \
  || fail "Composition teamenvironment is not in Pipeline mode"

FUNCTION="$(kubectl get composition teamenvironment -o jsonpath='{.spec.pipeline[0].functionRef.name}')"
[ "$FUNCTION" = "function-patch-and-transform" ] \
  || fail "the pipeline step uses function '$FUNCTION', expected function-patch-and-transform"
kubectl get function.pkg.crossplane.io "$FUNCTION" >/dev/null 2>&1 || fail "Function $FUNCTION is not installed"

REF="$("${XR[@]}" -o jsonpath='{.spec.crossplane.compositionRef.name}')"
[ "$REF" = "teamenvironment" ] || fail "outpost-env uses Composition '$REF', expected teamenvironment"

echo "PASS: Composition teamenvironment names function-patch-and-transform and outpost-env still uses it"
