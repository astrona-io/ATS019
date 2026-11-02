#!/usr/bin/env bash
# Grades the version migration. The two original objects must be the same objects as at the
# start (same UID, saved by the bootstrap in ConfigMap starfleet/database-baseline). Deleting
# the CRD and recreating the objects gives new UIDs and fails here. Both versions must return
# the same data, and v1alpha1 must be served, not the storage version, and deprecated with
# the exact warning text.
set -u

NS="outpost"
CRD="databases.platform.starfleet.io"
WARNING="platform.starfleet.io/v1alpha1 Database is deprecated; use platform.starfleet.io/v1"
CACHE=$(mktemp -d)
trap 'rm -rf "$CACHE"' EXIT
k() { kubectl --cache-dir="$CACHE" "$@"; }
fail() { echo "FAIL: $*"; exit 1; }
crd_field() { k get crd "$CRD" -o jsonpath="$1" 2>/dev/null; }
read_obj() { # version name jsonpath
  k -n "$NS" get "databases.$1.platform.starfleet.io" "$2" -o jsonpath="$3" 2>/dev/null
}

for name in orders-db billing-db; do
  baseline=$(k -n starfleet get configmap database-baseline -o jsonpath="{.data.$name}" 2>/dev/null)
  [[ -n "$baseline" ]] || fail "the ConfigMap starfleet/database-baseline is missing; do not delete it"
  [[ "$(read_obj v1 "$name" '{.metadata.uid}')" == "$baseline" ]] \
    || fail "$name is not the original object (its UID changed); update the CRD in place, do not delete and recreate"

  summary='{.spec.team}/{.spec.engine}/{.spec.storageGB}/{.spec.replicas}'
  via_v1=$(read_obj v1 "$name" "$summary")
  via_v1alpha1=$(read_obj v1alpha1 "$name" "$summary" 2>/dev/null)
  [[ -n "$via_v1" ]] || fail "cannot read $name through v1"
  [[ "$via_v1" == "$via_v1alpha1" ]] || fail "$name differs between versions: v1 '$via_v1', v1alpha1 '$via_v1alpha1'"
done
[[ "$(read_obj v1 orders-db '{.spec.team}/{.spec.engine}/{.spec.storageGB}')" == "orders/postgres/50" ]] \
  || fail "orders-db lost data; it must still be orders/postgres/50"
[[ "$(read_obj v1 billing-db '{.spec.team}/{.spec.engine}/{.spec.storageGB}')" == "billing/mysql/10" ]] \
  || fail "billing-db lost data; it must still be billing/mysql/10"
[[ "$(read_obj v1 orders-db '{.apiVersion}')" == "platform.starfleet.io/v1" ]] || fail "v1 reads must return apiVersion platform.starfleet.io/v1"
[[ "$(read_obj v1alpha1 orders-db '{.apiVersion}')" == "platform.starfleet.io/v1alpha1" ]] \
  || fail "v1alpha1 reads must return apiVersion platform.starfleet.io/v1alpha1"

[[ "$(crd_field '{.spec.versions[?(@.name=="v1alpha1")].deprecated}')" == "true" ]] || fail "v1alpha1 must be marked deprecated: true"
[[ "$(crd_field '{.spec.versions[?(@.name=="v1alpha1")].deprecationWarning}')" == "$WARNING" ]] \
  || fail "v1alpha1 deprecationWarning must be exactly: $WARNING"
[[ "$(crd_field '{.spec.versions[?(@.name=="v1")].deprecated}')" != "true" ]] || fail "v1 must not be deprecated"

warn_old=$(k -n "$NS" get databases.v1alpha1.platform.starfleet.io orders-db -o name 2>&1 >/dev/null)
[[ "$warn_old" == *"$WARNING"* ]] || fail "reading through v1alpha1 printed no deprecation warning, got: $warn_old"
warn_new=$(k -n "$NS" get databases.v1.platform.starfleet.io orders-db -o name 2>&1 >/dev/null)
[[ "$warn_new" != *"Warning"* ]] || fail "reading through v1 printed a warning: $warn_new"

echo "PASS: the original objects are untouched, both versions return the same data, and v1alpha1 warns that it is deprecated"
