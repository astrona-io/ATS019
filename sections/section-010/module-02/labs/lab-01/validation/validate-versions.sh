#!/usr/bin/env bash
# Grades the version list of the CRD: exactly v1alpha1 and v1, both served, v1 is the
# only storage version, conversion is None, and v1 is recorded in status.storedVersions.
set -u

CRD="teamenvironments.platform.starfleet.io"
fail() { echo "FAIL: $*"; exit 1; }

kubectl get crd "$CRD" >/dev/null 2>&1 || fail "the CRD $CRD does not exist"

versions=$(kubectl get crd "$CRD" \
  -o jsonpath='{range .spec.versions[*]}{.name}{" served="}{.served}{" storage="}{.storage}{"\n"}{end}')

[[ "$(echo "$versions" | wc -l | tr -d ' ')" == "2" ]] \
  || fail "the CRD must list exactly two versions, v1alpha1 and v1; found: $(echo "$versions" | tr '\n' ';')"
echo "$versions" | grep -qx 'v1alpha1 served=true storage=false' \
  || fail "v1alpha1 must stay served and must not be the storage version; found: $(echo "$versions" | tr '\n' ';')"
echo "$versions" | grep -qx 'v1 served=true storage=true' \
  || fail "v1 must be served and must be the storage version; found: $(echo "$versions" | tr '\n' ';')"

strategy=$(kubectl get crd "$CRD" -o jsonpath='{.spec.conversion.strategy}')
[[ -z "$strategy" || "$strategy" == "None" ]] \
  || fail "conversion strategy is '$strategy'; use None, because both versions have the same schema"

stored=$(kubectl get crd "$CRD" -o jsonpath='{.status.storedVersions}')
echo "$stored" | grep -q '"v1"' || fail "status.storedVersions is $stored and does not list v1"

echo "PASS: v1alpha1 and v1 are served, v1 is the storage version, conversion is None"
