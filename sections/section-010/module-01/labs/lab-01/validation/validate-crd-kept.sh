#!/usr/bin/env bash
# Grades that the CRD was changed in place: same group, kind, scope and version, and the
# TeamEnvironment alpha that existed before is still there.
set -u

CRD="teamenvironments.platform.starfleet.io"
fail() { echo "FAIL: $*"; exit 1; }

kubectl get crd "$CRD" >/dev/null 2>&1 || fail "the CRD $CRD does not exist"
[[ "$(kubectl get crd "$CRD" -o jsonpath='{.spec.names.kind}')" == "TeamEnvironment" ]] || fail "the kind is not TeamEnvironment"
[[ "$(kubectl get crd "$CRD" -o jsonpath='{.spec.scope}')" == "Namespaced" ]] || fail "the scope is not Namespaced"
[[ "$(kubectl get crd "$CRD" -o jsonpath='{.spec.versions[*].name}')" == "v1alpha1" ]] || fail "the CRD must have exactly the version v1alpha1"
[[ "$(kubectl get crd "$CRD" -o jsonpath='{.spec.versions[?(@.name=="v1alpha1")].served}')" == "true" ]] || fail "the version v1alpha1 is not served"
[[ "$(kubectl get crd "$CRD" -o jsonpath='{.spec.versions[?(@.name=="v1alpha1")].storage}')" == "true" ]] || fail "the version v1alpha1 is not the storage version"

team=$(kubectl -n outpost get teamenvironment alpha -o jsonpath='{.spec.team}' 2>/dev/null)
[[ "$team" == "outpost" ]] || fail "the TeamEnvironment alpha in outpost is missing or was changed (team '$team')"

echo "PASS: the CRD keeps its name, kind and version, and the TeamEnvironment alpha still exists"
