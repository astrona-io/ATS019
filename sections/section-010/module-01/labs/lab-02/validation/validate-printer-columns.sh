#!/usr/bin/env bash
# Grades what kubectl get shows: the columns Team, Size, Replicas and Age after Name, the
# short name teamenv, and the category platform.
set -u

fail() { echo "FAIL: $*"; exit 1; }
normalize() { tr -s ' \t' ' ' | sed 's/ *$//'; }

# The CRD update takes a moment to reach the API server: wait for the Team column.
for _ in $(seq 1 20); do
  header=$(kubectl -n outpost get teamenv alpha 2>/dev/null | sed -n 1p | tr '[:lower:]' '[:upper:]' | normalize)
  [[ "$header" == "NAME TEAM SIZE REPLICAS AGE" ]] && break
  sleep 3
done
kubectl -n outpost get teamenv alpha >/dev/null 2>&1 || fail "kubectl get teamenv does not work: the short name teamenv is missing"
[[ "$header" == "NAME TEAM SIZE REPLICAS AGE" ]] || fail "the columns are '$header', expected 'NAME TEAM SIZE REPLICAS AGE'"

row=$(kubectl -n outpost get teamenv alpha --no-headers | normalize)
read -r name team size replicas age <<<"$row"
[[ "$name" == "alpha" && "$team" == "outpost" && "$size" == "small" && "$replicas" == "2" ]] \
  || fail "the row of alpha is '$row', expected 'alpha outpost small 2 <age>'"
[[ -n "${age:-}" && "$age" != "<none>" ]] || fail "the Age column of alpha is empty"

listed=$(kubectl -n outpost get platform -o name 2>/dev/null)
[[ "$listed" == *"teamenvironment.platform.starfleet.io/alpha"* ]] || fail "kubectl get platform does not list alpha: the category platform is missing"

echo "PASS: kubectl get teamenv shows Team, Size, Replicas and Age, and the category platform lists the objects"
