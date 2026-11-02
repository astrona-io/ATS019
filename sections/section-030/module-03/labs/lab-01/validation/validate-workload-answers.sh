#!/usr/bin/env bash
set -uo pipefail

# Grader: scout answers a request from shuttle.
status=000
for i in $(seq 1 12); do
  status=$(kubectl -n outpost exec deploy/shuttle -- \
    curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://scout:9898 2>/dev/null || true)
  [ "$status" = "200" ] && break
  sleep 5
done
if [ "$status" != "200" ]; then
  echo "FAIL: answers - a request from shuttle to http://scout:9898 returned ${status}, expected 200"
  exit 1
fi
echo "PASS: answers - scout answers 200 to a request from shuttle"
