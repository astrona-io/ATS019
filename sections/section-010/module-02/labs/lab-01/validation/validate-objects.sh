#!/usr/bin/env bash
# Grades the objects and the schema: alpha and beta are the original objects (same uid)
# and readable through both versions, gamma exists and is read through v1, and both
# versions still reject bad input (the plausible wrong fix is to drop the schema checks).
set -u

CRD="teamenvironments.platform.starfleet.io"
fail() { echo "FAIL: $*"; exit 1; }

cache=$(mktemp -d)
trap 'rm -rf "$cache"' EXIT
k() { kubectl --cache-dir "$cache" "$@"; }

new_resource="teamenvironments.v1.platform.starfleet.io"
old_resource="teamenvironments.v1alpha1.platform.starfleet.io"

# Wait until the v1 endpoint answers.
ready=""
for _ in $(seq 1 30); do
  if k -n outpost get "$new_resource" >/dev/null 2>&1; then ready=yes; break; fi
  rm -rf "$cache"/*
  sleep 2
done
[[ -n "$ready" ]] || fail "the v1 endpoint of $CRD does not answer"

# The original objects must still exist: same uid as at the start.
for name in alpha beta; do
  want=$(kubectl -n starfleet get configmap seed-record -o jsonpath="{.data.$name-uid}" 2>/dev/null)
  [[ -n "$want" ]] || fail "the seed record for $name is missing; the lab cannot be graded"
  got=$(k -n outpost get "$new_resource" "$name" -o jsonpath='{.metadata.uid}' 2>/dev/null)
  [[ "$got" == "$want" ]] || fail "$name is not the original object (uid '$got', expected '$want'); do not delete and create objects again"
done

# Same data through both versions.
read_spec() { k -n outpost get "$1" "$2" -o jsonpath='{.spec.team}{" "}{.spec.size}{" "}{.spec.replicas}' 2>/dev/null; }
[[ "$(read_spec "$new_resource" alpha)" == "outpost small 2" ]] || fail "alpha through v1 is '$(read_spec "$new_resource" alpha)', expected 'outpost small 2'"
[[ "$(read_spec "$old_resource" alpha)" == "outpost small 2" ]] || fail "alpha through v1alpha1 is '$(read_spec "$old_resource" alpha)', expected 'outpost small 2'"
[[ "$(read_spec "$new_resource" beta)" == "outpost medium 3" ]] || fail "beta through v1 is '$(read_spec "$new_resource" beta)', expected 'outpost medium 3'"
[[ "$(read_spec "$old_resource" beta)" == "outpost medium 3" ]] || fail "beta through v1alpha1 is '$(read_spec "$old_resource" beta)', expected 'outpost medium 3'"

# gamma: created through v1.
[[ "$(read_spec "$new_resource" gamma)" == "outpost large 4" ]] || fail "gamma through v1 is '$(read_spec "$new_resource" gamma)', expected 'outpost large 4'"
api=$(k -n outpost get "$new_resource" gamma -o jsonpath='{.apiVersion}' 2>/dev/null)
[[ "$api" == "platform.starfleet.io/v1" ]] || fail "gamma is served as '$api', expected platform.starfleet.io/v1"

# The schema must still work in both versions.
check_version() {
  version="$1"
  default=$(k apply --dry-run=server -o jsonpath='{.spec.replicas}' -f - 2>/dev/null <<YAML
apiVersion: platform.starfleet.io/$version
kind: TeamEnvironment
metadata:
  name: probe-default
  namespace: outpost
spec:
  team: outpost
  size: small
YAML
)
  [[ "$default" == "1" ]] || fail "$version does not default spec.replicas to 1 (got '$default')"

  for bad in "size: huge" "size: small
  replicas: 9" "size: small
  replcas: 2"; do
    if k apply --dry-run=server -f - >/dev/null 2>&1 <<YAML
apiVersion: platform.starfleet.io/$version
kind: TeamEnvironment
metadata:
  name: probe-bad
  namespace: outpost
spec:
  team: outpost
  $bad
YAML
    then
      fail "$version accepted invalid input ($(echo "$bad" | tr '\n' ' ')); keep the schema checks in both versions"
    fi
  done

  if k apply --dry-run=server -f - >/dev/null 2>&1 <<YAML
apiVersion: platform.starfleet.io/$version
kind: TeamEnvironment
metadata:
  name: probe-no-team
  namespace: outpost
spec:
  size: small
YAML
  then
    fail "$version accepted an object without spec.team"
  fi
}
check_version v1
check_version v1alpha1

echo "PASS: alpha and beta are the original objects, gamma was created through v1, both versions keep the schema checks"
