#!/usr/bin/env bash
# Check: the request reports Synced and Ready, and it owns two composed Objects
# that Crossplane created from the Composition.
set -uo pipefail
fail() { echo "FAIL: $1"; exit 1; }
XR=(kubectl -n outpost get teamenvironment outpost-env)

for i in $(seq 1 36); do
  SYNCED="$("${XR[@]}" -o jsonpath='{.status.conditions[?(@.type=="Synced")].status}' 2>/dev/null)"
  READY="$("${XR[@]}" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
  [ "$SYNCED" = "True" ] && [ "$READY" = "True" ] && break
  sleep 5
done
[ "$SYNCED" = "True" ] || fail "Synced is '$SYNCED'; read the conditions and events of outpost-env"
[ "$READY" = "True" ] || fail "Ready is '$READY'; read the conditions of outpost-env"

COMPOSED="$(kubectl -n outpost get objects.kubernetes.m.crossplane.io -l crossplane.io/composite=outpost-env -o name 2>/dev/null | wc -l | tr -d ' ')"
if [ "$COMPOSED" -lt 2 ]; then
  COMPOSED="$("${XR[@]}" -o jsonpath='{range .spec.crossplane.resourceRefs[*]}{.kind}{"\n"}{end}' 2>/dev/null | grep -c '^Object$')"
fi
[ "$COMPOSED" -ge 2 ] || fail "outpost-env owns $COMPOSED composed Objects, expected 2"

echo "PASS: outpost-env is Synced and Ready and owns $COMPOSED composed Objects"
