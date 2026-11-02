#!/usr/bin/env bash
# Grades the status subresource on v1 with a temporary object, grader-status:
#   - a write to the main endpoint cannot change status,
#   - a write to the status endpoint changes status and cannot change spec,
#   - status is typed, so a text value for readyReplicas is refused.
# Without the subresource, the main endpoint changes status and these checks fail.
set -u

NS="outpost"
RES="databases.v1.platform.starfleet.io"
NAME="grader-status"
CACHE=$(mktemp -d)
cleanup() { kubectl --cache-dir="$CACHE" -n "$NS" delete "$RES" "$NAME" --ignore-not-found --wait=false >/dev/null 2>&1; rm -rf "$CACHE"; }
trap cleanup EXIT
k() { kubectl --cache-dir="$CACHE" "$@"; }
fail() { echo "FAIL: $*"; exit 1; }
value() { k -n "$NS" get "$RES" "$NAME" -o jsonpath="$1" 2>/dev/null; }

k -n "$NS" delete "$RES" "$NAME" --ignore-not-found >/dev/null 2>&1
k create -f - >/dev/null 2>&1 <<YAML || fail "cannot create a valid v1 Database for the status check"
apiVersion: platform.starfleet.io/v1
kind: Database
metadata:
  name: $NAME
  namespace: $NS
spec:
  team: grader
  engine: postgres
  storageGB: 10
YAML

# 1. The main endpoint ignores status.
k -n "$NS" patch "$RES" "$NAME" --type merge -p '{"status":{"readyReplicas":2,"phase":"Ready"}}' >/dev/null 2>&1
[[ -z "$(value '{.status.readyReplicas}')" ]] \
  || fail "a write to the main endpoint changed status; enable the status subresource on v1"

# 2. The status endpoint writes status.
k -n "$NS" patch "$RES" "$NAME" --subresource=status --type merge \
  -p '{"status":{"readyReplicas":2,"phase":"Ready"}}' >/dev/null 2>&1 \
  || fail "the status endpoint refused a write; enable the status subresource on v1"
[[ "$(value '{.status.readyReplicas}/{.status.phase}')" == "2/Ready" ]] \
  || fail "status.readyReplicas (integer) and status.phase (string) were not stored; declare them in the v1 schema"

# 3. A spec write that carries a status value keeps the old status.
k -n "$NS" patch "$RES" "$NAME" --type merge -p '{"spec":{"storageGB":20},"status":{"readyReplicas":0}}' >/dev/null 2>&1 \
  || fail "a valid spec update was refused"
[[ "$(value '{.spec.storageGB}/{.status.readyReplicas}')" == "20/2" ]] \
  || fail "a spec update must change spec and leave status alone, found '$(value '{.spec.storageGB}/{.status.readyReplicas}')'"

# 4. The status endpoint cannot change spec.
k -n "$NS" patch "$RES" "$NAME" --subresource=status --type merge \
  -p '{"spec":{"storageGB":99},"status":{"readyReplicas":3}}' >/dev/null 2>&1
[[ "$(value '{.spec.storageGB}/{.status.readyReplicas}')" == "20/3" ]] \
  || fail "a status write must change status and leave spec alone, found '$(value '{.spec.storageGB}/{.status.readyReplicas}')'"

# 5. Status is typed.
if k -n "$NS" patch "$RES" "$NAME" --subresource=status --type merge -p '{"status":{"readyReplicas":"many"}}' >/dev/null 2>&1; then
  fail "status.readyReplicas accepted a text value; give it type: integer"
fi

echo "PASS: v1 has a status subresource: spec writes cannot change status, status writes cannot change spec, status is typed"
