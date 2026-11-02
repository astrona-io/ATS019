#!/usr/bin/env bash
# Check: the composed Service answers a request from shuttle with 200, and the
# pods carry the team label from the request.
set -uo pipefail
fail() { echo "FAIL: $1"; exit 1; }

TEAM="$(kubectl -n outpost get deployment scout -o jsonpath='{.spec.template.metadata.labels.team}' 2>/dev/null)"
[ "$TEAM" = "drifter" ] || fail "Deployment scout pod label team is '$TEAM', expected drifter"

for i in $(seq 1 24); do
  CODE="$(kubectl -n outpost exec deploy/shuttle -- curl -s -o /dev/null -m 5 -w '%{http_code}' http://scout:9898 2>/dev/null)"
  if [ "$CODE" = "200" ]; then
    echo "PASS: shuttle gets 200 from Service scout and pods carry team=drifter"
    exit 0
  fi
  sleep 5
done
fail "request from shuttle to http://scout:9898 returned '$CODE', expected 200"
