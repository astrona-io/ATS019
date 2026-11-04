#!/usr/bin/env bash
# Shared live-state checks. This helper is sourced, not a graded check.
set -euo pipefail
fail() { echo "FAIL: $*"; exit 1; }
field() { kubectl "$@" 2>/dev/null || fail "cannot read $*"; }
saved() { field -n starfleet get configmap lab-state -o "jsonpath={.data.$1}"; }
xr_field() { field -n outpost get teamenvironment "$1" -o "jsonpath={$2}"; }
comp_field() { field get composition scout-stateful -o "jsonpath={$1}"; }
require_equal() { [ -n "$1" ] && [ "$1" = "$2" ] || fail "$3"; }
check_ready() {
  local name="$1" condition
  for condition in Synced Ready; do
    require_equal "$(xr_field "$name" ".status.conditions[?(@.type==\"$condition\")].status")" True "$name is not $condition"
  done
}
check_owned_service() {
  local name="$1" uid
  uid="$(xr_field "$name" '.metadata.uid')"
  require_equal "$(field -n outpost get service "$name" -o 'jsonpath={.metadata.ownerReferences[?(@.controller==true)].uid}')" "$uid" "$name Service is not controlled by its composite resource"
  require_equal "$(field -n outpost get service "$name" -o 'jsonpath={.metadata.annotations.crossplane\.io/composition-resource-name}')" service "$name Service did not come from the service template"
}
