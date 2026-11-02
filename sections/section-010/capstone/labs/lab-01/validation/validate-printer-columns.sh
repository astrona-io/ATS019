#!/usr/bin/env bash
# Grades the printer columns and the short name on v1 with a temporary object, grader-columns.
# The Ready column must read .status.readyReplicas, so the check writes a status value and
# looks for it in the table. Setting the right header over the wrong jsonPath fails here.
set -u

NS="outpost"
RES="databases.v1.platform.starfleet.io"
NAME="grader-columns"
CACHE=$(mktemp -d)
cleanup() { kubectl --cache-dir="$CACHE" -n "$NS" delete "$RES" "$NAME" --ignore-not-found --wait=false >/dev/null 2>&1; rm -rf "$CACHE"; }
trap cleanup EXIT
k() { kubectl --cache-dir="$CACHE" "$@"; }
fail() { echo "FAIL: $*"; exit 1; }

k -n "$NS" delete "$RES" "$NAME" --ignore-not-found >/dev/null 2>&1
k create -f - >/dev/null 2>&1 <<YAML || fail "cannot create a valid v1 Database for the column check"
apiVersion: platform.starfleet.io/v1
kind: Database
metadata:
  name: $NAME
  namespace: $NS
spec:
  team: grader
  engine: postgres
YAML
k -n "$NS" patch "$RES" "$NAME" --subresource=status --type merge -p '{"status":{"readyReplicas":2}}' >/dev/null 2>&1 \
  || fail "cannot write status.readyReplicas through the status subresource"

table=$(k -n "$NS" get "$RES" 2>/dev/null)
header=$(echo "$table" | head -1 | tr -s ' ')
[[ "$header" == "NAME ENGINE STORAGE REPLICAS READY AGE" ]] \
  || fail "the v1 table header must be NAME ENGINE STORAGE REPLICAS READY AGE, found: $header"

row=$(echo "$table" | awk -v n="$NAME" '$1 == n {print $1, $2, $3, $4, $5}')
[[ "$row" == "grader-columns postgres 10 1 2" ]] \
  || fail "the row of $NAME must read 'grader-columns postgres 10 1 2' (name, engine, storage, replicas, ready), found '$row'"

k -n "$NS" get db -o name 2>/dev/null | grep -q 'orders-db' \
  || fail "kubectl get db does not list orders-db; add db to spec.names.shortNames"

echo "PASS: kubectl get shows NAME ENGINE STORAGE REPLICAS READY AGE with the right values, and db is a short name"
