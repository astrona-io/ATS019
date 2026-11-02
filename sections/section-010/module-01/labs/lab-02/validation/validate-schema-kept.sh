#!/usr/bin/env bash
# Grades that the typed schema from the start state is still in force and the CRD was
# changed in place: same kind, scope and version, alpha still exists, the limits still refuse
# bad values, and no x-kubernetes-preserve-unknown-fields.
set -u

CRD="teamenvironments.platform.starfleet.io"
fail() { echo "FAIL: $*"; exit 1; }

dry_run_create() {
  printf '{"apiVersion":"platform.starfleet.io/v1alpha1","kind":"TeamEnvironment","metadata":{"name":"grader-check","namespace":"outpost"},"spec":%s}' "$1" \
    | kubectl create --dry-run=server -f - -o name 2>&1
}

kubectl get crd "$CRD" >/dev/null 2>&1 || fail "the CRD $CRD does not exist"
[[ "$(kubectl get crd "$CRD" -o jsonpath='{.spec.names.kind}')" == "TeamEnvironment" ]] || fail "the kind is not TeamEnvironment"
[[ "$(kubectl get crd "$CRD" -o jsonpath='{.spec.scope}')" == "Namespaced" ]] || fail "the scope is not Namespaced"
[[ "$(kubectl get crd "$CRD" -o jsonpath='{.spec.versions[*].name}')" == "v1alpha1" ]] || fail "the CRD must have exactly the version v1alpha1"
[[ "$(kubectl -n outpost get teamenvironment alpha -o jsonpath='{.spec.team}' 2>/dev/null)" == "outpost" ]] || fail "the TeamEnvironment alpha in outpost is missing or was changed"

if kubectl get crd "$CRD" -o jsonpath='{.spec.versions}' | grep -q 'x-kubernetes-preserve-unknown-fields'; then
  fail "the schema uses x-kubernetes-preserve-unknown-fields"
fi

# The limits of the start state must still refuse bad input.
dry_run_create '{"team":"outpost","size":"huge","contact":"lead@outpost.starfleet.io"}' >/dev/null && fail "the API server accepted size huge"
dry_run_create '{"team":"outpost","size":"large","replicas":50,"contact":"lead@outpost.starfleet.io"}' >/dev/null && fail "the API server accepted 50 replicas"
dry_run_create '{"team":"outpost","size":"small","contact":"nobody"}' >/dev/null && fail "the API server accepted the contact nobody"
dry_run_create '{"size":"small","contact":"lead@outpost.starfleet.io"}' >/dev/null && fail "the API server accepted an object without a team"
dry_run_create '{"team":"outpost","size":"small","replcas":2,"contact":"lead@outpost.starfleet.io"}' >/dev/null && fail "the API server accepted the misspelled field replcas"

replicas=$(printf '{"apiVersion":"platform.starfleet.io/v1alpha1","kind":"TeamEnvironment","metadata":{"name":"grader-check","namespace":"outpost"},"spec":{"team":"outpost","size":"medium","contact":"lead@outpost.starfleet.io"}}' \
  | kubectl create --dry-run=server -f - -o jsonpath='{.spec.replicas}' 2>/dev/null)
[[ "$replicas" == "1" ]] || fail "the default replicas 1 is gone (got '$replicas')"

echo "PASS: the CRD keeps its typed schema, its version and the object alpha"
