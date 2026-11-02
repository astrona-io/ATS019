#!/usr/bin/env bash
# Behaviour check: a client pod sends a request to the Service that the
# Composition created for the request.
set -uo pipefail

code=""
for i in $(seq 1 12); do
  code=$(kubectl -n outpost exec deploy/shuttle -- \
    curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://scout:9898 2>/dev/null)
  [ "$code" = "200" ] && break
  sleep 5
done
if [ "$code" = "200" ]; then
  echo "PASS: a request from shuttle to http://scout:9898 returns 200"
else
  echo "FAIL: a request from shuttle to http://scout:9898 returned '$code', expected 200"; exit 1
fi
