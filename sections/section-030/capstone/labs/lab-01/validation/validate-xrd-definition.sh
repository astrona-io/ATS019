#!/usr/bin/env bash
# Grader: the XRD exists, is Established, has the required identity and declares the
# status field the Composition writes to. A status field that is not declared is pruned.
set -uo pipefail
XRD=teamenvironments.platform.starfleet.io
fail() { echo "FAIL: xrd-definition - $1"; exit 1; }
field() { kubectl get xrd "$XRD" -o jsonpath="$1" 2>/dev/null; }

kubectl get xrd "$XRD" >/dev/null 2>&1 || fail "XRD $XRD does not exist"
[ "$(field '{.apiVersion}')" = "apiextensions.crossplane.io/v2" ] || fail "the XRD is not apiextensions.crossplane.io/v2"
[ "$(field '{.spec.scope}')" = "Namespaced" ] || fail "spec.scope is '$(field '{.spec.scope}')', expected Namespaced"
[ "$(field '{.spec.group}')" = "platform.starfleet.io" ] || fail "spec.group is not platform.starfleet.io"
[ "$(field '{.spec.names.kind}')" = "TeamEnvironment" ] || fail "spec.names.kind is not TeamEnvironment"
[ "$(field '{.spec.names.plural}')" = "teamenvironments" ] || fail "spec.names.plural is not teamenvironments"
[ "$(field '{.spec.versions[0].name}')" = "v1alpha1" ] || fail "the first version is not v1alpha1"
[ "$(field '{.spec.versions[0].served}')" = "true" ] || fail "v1alpha1 is not served"
[ "$(field '{.spec.versions[0].referenceable}')" = "true" ] || fail "v1alpha1 is not referenceable"

established=$(field '{.status.conditions[?(@.type=="Established")].status}')
[ "$established" = "True" ] || fail "the XRD is not Established (status '${established}'); read its conditions"
[ "$(kubectl get crd "$XRD" -o jsonpath='{.spec.scope}' 2>/dev/null)" = "Namespaced" ] \
  || fail "the generated CRD is not namespaced"

status_type=$(field '{.spec.versions[0].schema.openAPIV3Schema.properties.status.properties.availableReplicas.type}')
[ "$status_type" = "integer" ] \
  || fail "the schema does not declare status.availableReplicas as an integer (found '${status_type:-nothing}')"

echo "PASS: xrd-definition - the XRD is Established, namespaced and declares status.availableReplicas"
