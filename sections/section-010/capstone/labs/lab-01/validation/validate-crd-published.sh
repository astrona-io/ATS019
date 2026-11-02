#!/usr/bin/env bash
# Grades the published CRD: names, scope, two served versions, v1 as the storage version,
# no conversion webhook, and no x-kubernetes-preserve-unknown-fields: true anywhere.
# The preserve-unknown-fields shortcut makes schema errors disappear instead of fixing them.
set -u

CRD="databases.platform.starfleet.io"
CACHE=$(mktemp -d)
trap 'rm -rf "$CACHE"' EXIT
k() { kubectl --cache-dir="$CACHE" "$@"; }
fail() { echo "FAIL: $*"; exit 1; }

k get crd "$CRD" >/dev/null 2>&1 || fail "the CRD $CRD does not exist; do not delete it, update it"

field() { k get crd "$CRD" -o jsonpath="$1" 2>/dev/null; }

[[ "$(field '{.spec.group}')" == "platform.starfleet.io" ]] || fail "spec.group must be platform.starfleet.io"
[[ "$(field '{.spec.scope}')" == "Namespaced" ]] || fail "spec.scope must be Namespaced"
[[ "$(field '{.spec.names.kind}')" == "Database" ]] || fail "spec.names.kind must be Database"
[[ "$(field '{.spec.names.plural}')" == "databases" ]] || fail "spec.names.plural must be databases"
[[ "$(field '{.spec.names.shortNames}')" == *'"db"'* ]] || fail "spec.names.shortNames must contain db"
[[ "$(field '{.status.conditions[?(@.type=="Established")].status}')" == "True" ]] \
  || fail "the CRD is not Established; read its status conditions"

versions=$(field '{range .spec.versions[*]}{.name}{"\n"}{end}' | sort | tr '\n' ' ')
[[ "$versions" == "v1 v1alpha1 " ]] || fail "the CRD must list exactly the versions v1alpha1 and v1, found: $versions"

for version in v1alpha1 v1; do
  [[ "$(field "{.spec.versions[?(@.name==\"$version\")].served}")" == "true" ]] \
    || fail "version $version must stay served"
done
[[ "$(field '{.spec.versions[?(@.name=="v1")].storage}')" == "true" ]] || fail "v1 must be the storage version"
[[ "$(field '{.spec.versions[?(@.name=="v1alpha1")].storage}')" == "false" ]] \
  || fail "v1alpha1 must not be the storage version; only one version can be"
[[ "$(field '{.status.storedVersions}')" == *'"v1"'* ]] \
  || fail "status.storedVersions does not list v1; the storage version is not v1 yet"

strategy=$(field '{.spec.conversion.strategy}')
[[ -z "$strategy" || "$strategy" == "None" ]] || fail "conversion strategy is '$strategy'; this CRD must use None"

if k get crd "$CRD" -o json | tr -d ' \n' | grep -q '"x-kubernetes-preserve-unknown-fields":true'; then
  fail "the schema still sets x-kubernetes-preserve-unknown-fields: true; declare the fields instead"
fi

echo "PASS: $CRD serves v1alpha1 and v1, stores v1, uses conversion None and declares every field"
