#!/usr/bin/env bash
# Check: a request from shuttle reaches the composed workload and returns 200.
set -uo pipefail
fail() { echo "FAIL: $1"; exit 1; }

for i in $(seq 1 36); do
  CODE="$(kubectl -n outpost exec deploy/shuttle -- curl -s -o /dev/null -m 5 -w '%{http_code}' http://scout:9898 2>/dev/null)"
  if [ "$CODE" = "200" ]; then
    echo "PASS: shuttle gets 200 from http://scout:9898"
    exit 0
  fi
  sleep 5
done
fail "request from shuttle to http://scout:9898 returned '$CODE', expected 200"
