#!/usr/bin/env bash
# Grades the scale subresource on v1 with a temporary object, grader-scale (30 GB, 1 replica):
# `kubectl scale` must change spec.replicas and nothing else, and the scale endpoint must read
# its status from status.readyReplicas. A wrong specReplicasPath (for example .spec.storageGB)
# changes the wrong field and fails.
set -u

NS="outpost"
RES="databases.v1.platform.starfleet.io"
NAME="grader-scale"
CACHE=$(mktemp -d)
cleanup() { kubectl --cache-dir="$CACHE" -n "$NS" delete "$RES" "$NAME" --ignore-not-found --wait=false >/dev/null 2>&1; rm -rf "$CACHE"; }
trap cleanup EXIT
k() { kubectl --cache-dir="$CACHE" "$@"; }
fail() { echo "FAIL: $*"; exit 1; }
value() { k -n "$NS" get "$RES" "$NAME" -o jsonpath="$1" 2>/dev/null; }
scale_json() { k get --raw "/apis/platform.starfleet.io/v1/namespaces/$NS/databases/$NAME/scale" 2>/dev/null; }

k -n "$NS" delete "$RES" "$NAME" --ignore-not-found >/dev/null 2>&1
k create -f - >/dev/null 2>&1 <<YAML || fail "cannot create a valid v1 Database for the scale check"
apiVersion: platform.starfleet.io/v1
kind: Database
metadata:
  name: $NAME
  namespace: $NS
spec:
  team: grader
  engine: postgres
  storageGB: 30
  replicas: 1
YAML

k -n "$NS" scale "$RES/$NAME" --replicas=3 >/dev/null 2>&1 \
  || fail "kubectl scale failed on the v1 Database; enable the scale subresource on v1"
[[ "$(value '{.spec.replicas}/{.spec.storageGB}')" == "3/30" ]] \
  || fail "kubectl scale must set spec.replicas to 3 and keep storageGB at 30, found '$(value '{.spec.replicas}/{.spec.storageGB}')'; check specReplicasPath"

scale_json | grep -qF '"spec":{"replicas":3}' \
  || fail "the scale endpoint does not report spec.replicas 3 from .spec.replicas"

k -n "$NS" patch "$RES" "$NAME" --subresource=status --type merge -p '{"status":{"readyReplicas":3}}' >/dev/null 2>&1 \
  || fail "cannot write status.readyReplicas through the status subresource"
scale_json | grep -qF '"status":{"replicas":3}' \
  || fail "the scale endpoint does not report status.replicas 3 from .status.readyReplicas; check statusReplicasPath"

if k -n "$NS" scale "$RES/$NAME" --replicas=9 >/dev/null 2>&1; then
  fail "kubectl scale accepted 9 replicas; the schema allows at most 5"
fi
[[ "$(value '{.spec.replicas}')" == "3" ]] || fail "a refused scale must leave spec.replicas at 3"

echo "PASS: kubectl scale changes spec.replicas, the scale endpoint reads status.readyReplicas, and the schema still limits replicas"
