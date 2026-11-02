#!/usr/bin/env bash
# Check 4: the webhook accepts POST /provision on port 12000 and nothing else.
# The grader sends the tier trial, so a correct Sensor starts no Workflow.
set -uo pipefail
NS=starfleet
fail=0
pass_line() { echo "PASS: $1"; }
fail_line() { echo "FAIL: $1"; fail=1; }

if ! kubectl -n "$NS" get deploy/shuttle >/dev/null 2>&1; then
  echo "FAIL: the shuttle Deployment does not exist in $NS"; exit 1
fi
kubectl -n "$NS" get eventbus default >/dev/null 2>&1 || { echo "FAIL: EventBus default does not exist in $NS"; exit 1; }
kubectl -n "$NS" get eventsource provision >/dev/null 2>&1 || { echo "FAIL: EventSource provision does not exist in $NS"; exit 1; }
kubectl -n "$NS" get service provision-eventsource-svc >/dev/null 2>&1 \
  || { echo "FAIL: Service provision-eventsource-svc does not exist (the EventSource needs a service block)"; exit 1; }

URL=http://provision-eventsource-svc.starfleet.svc:12000
status_of() { # status_of <method> <path>
  kubectl -n "$NS" exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}' --max-time 10 \
    -X "$1" -H 'Content-Type: application/json' -d '{"team":"grader-webhook","tier":"trial"}' "$URL$2" 2>/dev/null
}

code=""
for _ in $(seq 1 30); do
  code=$(status_of POST /provision)
  [ "$code" = "200" ] && break
  sleep 3
done
if [ "$code" = "200" ]; then
  pass_line "POST /provision returns 200"
else
  fail_line "POST /provision returned '${code}', expected 200. Read the EventSource and compare its endpoint with the URL in the task"
fi

other=$(status_of POST /other)
if [ "$other" != "200" ]; then pass_line "POST /other is not accepted"; else fail_line "POST /other returned 200: the endpoint must be /provision only"; fi
get_code=$(status_of GET /provision)
if [ "$get_code" != "200" ]; then pass_line "GET /provision is not accepted"; else fail_line "GET /provision returned 200: the method must be POST only"; fi
exit $fail
