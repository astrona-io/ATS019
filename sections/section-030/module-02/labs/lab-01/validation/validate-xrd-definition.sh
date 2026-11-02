#!/usr/bin/env bash
# Check: the XRD exists, is Established and has the required identity.
set -uo pipefail
XRD=probeenvironments.platform.starfleet.io
fail() { echo "FAIL: $1"; exit 1; }

kubectl get xrd "$XRD" >/dev/null 2>&1 || fail "XRD $XRD does not exist"
field() { kubectl get xrd "$XRD" -o jsonpath="$1" 2>/dev/null; }

[ "$(field '{.spec.scope}')" = "Namespaced" ] || fail "spec.scope is '$(field '{.spec.scope}')', expected Namespaced"
[ "$(field '{.spec.group}')" = "platform.starfleet.io" ] || fail "spec.group is not platform.starfleet.io"
[ "$(field '{.spec.names.kind}')" = "ProbeEnvironment" ] || fail "spec.names.kind is not ProbeEnvironment"
[ "$(field '{.spec.names.plural}')" = "probeenvironments" ] || fail "spec.names.plural is not probeenvironments"
[ "$(field '{.spec.versions[0].name}')" = "v1alpha1" ] || fail "first version is not v1alpha1"
[ "$(field '{.spec.versions[0].served}')" = "true" ] || fail "v1alpha1 is not served"
[ "$(field '{.spec.versions[0].referenceable}')" = "true" ] || fail "v1alpha1 is not referenceable"

ESTABLISHED="$(field '{.status.conditions[?(@.type=="Established")].status}')"
[ "$ESTABLISHED" = "True" ] || fail "XRD is not Established (status '$ESTABLISHED'); read its conditions"

CRD_SCOPE="$(kubectl get crd "$XRD" -o jsonpath='{.spec.scope}' 2>/dev/null)"
[ "$CRD_SCOPE" = "Namespaced" ] || fail "generated CRD scope is '$CRD_SCOPE', expected Namespaced"

echo "PASS: XRD $XRD is Established, namespaced, kind ProbeEnvironment, version v1alpha1"
