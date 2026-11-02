#!/usr/bin/env bash
# Grades the deprecation of v1alpha1: the CRD fields and the real warning that kubectl
# prints on standard error. A request through v1 must not warn.
set -u

CRD="teamenvironments.platform.starfleet.io"
fail() { echo "FAIL: $*"; exit 1; }

kubectl get crd "$CRD" >/dev/null 2>&1 || fail "the CRD $CRD does not exist"

old_deprecated=$(kubectl get crd "$CRD" -o jsonpath='{.spec.versions[?(@.name=="v1alpha1")].deprecated}')
[[ "$old_deprecated" == "true" ]] || fail "v1alpha1 is not marked deprecated: true"

old_warning=$(kubectl get crd "$CRD" -o jsonpath='{.spec.versions[?(@.name=="v1alpha1")].deprecationWarning}')
[[ -n "$old_warning" ]] || fail "v1alpha1 has no deprecationWarning"
echo "$old_warning" | grep -Eq 'use platform\.starfleet\.io/v1($|[^a-z0-9])' \
  || fail "the deprecationWarning is '$old_warning' and does not tell users to use platform.starfleet.io/v1"

new_deprecated=$(kubectl get crd "$CRD" -o jsonpath='{.spec.versions[?(@.name=="v1")].deprecated}')
[[ "$new_deprecated" != "true" ]] || fail "v1 must not be deprecated"

# Behaviour: use a fresh discovery cache, so a stale cache cannot hide the change.
cache=$(mktemp -d)
trap 'rm -rf "$cache"' EXIT

old_resource="teamenvironments.v1alpha1.platform.starfleet.io"
new_resource="teamenvironments.v1.platform.starfleet.io"

warned=""
for _ in $(seq 1 30); do
  stderr=$(kubectl --cache-dir "$cache" -n outpost get "$old_resource" alpha -o name 2>&1 >/dev/null)
  if echo "$stderr" | grep -q "Warning:.*deprecated"; then warned="$stderr"; break; fi
  rm -rf "$cache"/*
  sleep 2
done
[[ -n "$warned" ]] || fail "a request through v1alpha1 prints no deprecation warning; last stderr: '$stderr'"

stderr_new=$(kubectl --cache-dir "$cache" -n outpost get "$new_resource" alpha -o name 2>&1 >/dev/null)
[[ -z "$stderr_new" ]] || fail "a request through v1 prints a warning or error: '$stderr_new'"

echo "PASS: v1alpha1 is deprecated and kubectl prints the warning; v1 prints none"
