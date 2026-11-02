#!/usr/bin/env bash
# Grader helpers. Each validate-*.sh script is standalone and exits 0 (pass)
# or non-zero (fail).
NS=starfleet
EVENT_URL=http://provision-eventsource-svc.starfleet.svc:12000/provision

fail() { echo "FAIL: $1"; exit 1; }
pass() { echo "PASS: $1"; exit 0; }

# send_event <team> <tier>: posts a JSON event from the shuttle pod and prints the HTTP status code.
send_event() {
  kubectl -n "$NS" exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}' --max-time 10 \
    -X POST -H 'Content-Type: application/json' \
    -d "{\"team\":\"$1\",\"tier\":\"$2\"}" "$EVENT_URL" 2>/dev/null
}

# send_event_until_accepted <team> <tier>: retries for up to 90 seconds until the EventSource answers 200.
send_event_until_accepted() {
  local code
  for _ in $(seq 1 30); do
    code=$(send_event "$1" "$2")
    [ "$code" = "200" ] && return 0
    sleep 3
  done
  return 1
}

# workflows_for_team <team>: prints the names of Workflows whose team parameter equals <team>.
workflows_for_team() {
  kubectl -n "$NS" get workflows \
    -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.arguments.parameters[?(@.name=="team")].value}{"\n"}{end}' 2>/dev/null |
    awk -v team="$1" '$2 == team { print $1 }'
}

# wait_for_workflow <team> <seconds>: prints the first matching Workflow name, or returns 1.
wait_for_workflow() {
  local name
  for _ in $(seq 1 $(( $2 / 2 ))); do
    name=$(workflows_for_team "$1" | head -n 1)
    if [ -n "$name" ]; then echo "$name"; return 0; fi
    sleep 2
  done
  return 1
}

# new_team <label>: prints a unique team name, so a hard-coded value cannot pass.
new_team() { echo "grader-$1-$(date +%s)-$RANDOM"; }

kubectl -n "$NS" get deploy/shuttle >/dev/null 2>&1 || fail "the shuttle Deployment does not exist in $NS"

# Check 4: the fix did not widen the Sensor permissions.
SA="system:serviceaccount:$NS:operate-workflow-sa"
can_i() { kubectl auth can-i "$@" --as="$SA" 2>/dev/null; }
[ "$(can_i create workflows.argoproj.io -n "$NS")" = "yes" ] || fail "operate-workflow-sa lost the permission to create workflows"
[ "$(can_i '*' '*' -n "$NS")" = "no" ] || fail "operate-workflow-sa has wildcard permissions in $NS"
[ "$(can_i '*' '*' --all-namespaces)" = "no" ] || fail "operate-workflow-sa is cluster-admin or has a cluster-wide wildcard"
[ "$(can_i get secrets -n "$NS")" = "no" ] || fail "operate-workflow-sa can read Secrets"
pass "operate-workflow-sa can create workflows and has no broad permissions"
