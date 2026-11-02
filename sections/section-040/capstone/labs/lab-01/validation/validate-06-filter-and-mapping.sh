#!/usr/bin/env bash
# Check 6: the Sensor filters on body.tier and copies body.team into the Workflow.
#   - a premium order starts a Workflow from request-environment with a team that
#     the grader made up, so a fixed team name in the Sensor fails
#   - a trial order starts no Workflow and creates no TeamEnvironment, so a Sensor
#     without a filter fails
# The grader removes what the premium order built when it is done.
set -u
NS=starfleet
EVENT_URL=http://provision-eventsource-svc.starfleet.svc:12000/provision
TE=teamenvironments.platform.starfleet.io

fail() { echo "FAIL: $1"; exit 1; }
pass() { echo "PASS: $1"; exit 0; }

# send_event <team> <tier>: posts a JSON order from shuttle and prints the HTTP status code.
send_event() {
  kubectl -n "$NS" exec deploy/shuttle -- curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
    -X POST -H "Content-Type: application/json" \
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
    -o jsonpath="{range .items[*]}{.metadata.name}{\" \"}{.spec.arguments.parameters[?(@.name==\"team\")].value}{\"\n\"}{end}" 2>/dev/null |
    awk -v team="$1" "\$2 == team { print \$1 }"
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

# new_team <label>: prints a unique DNS-safe team name, so a fixed value cannot pass.
new_team() { echo "grader-$1-$(date +%s)-$RANDOM"; }

# clear_environments: deletes every TeamEnvironment in outpost and waits until the scout Deployment is gone.
clear_environments() {
  kubectl -n outpost delete "$TE" --all --wait=true --timeout=120s >/dev/null 2>&1
  for _ in $(seq 1 40); do
    kubectl -n outpost get deployment scout >/dev/null 2>&1 || return 0
    sleep 3
  done
  return 1
}

kubectl -n "$NS" get deploy/shuttle >/dev/null 2>&1 || fail "the shuttle Deployment does not exist in $NS"
clear_environments || fail "the grader could not remove the old TeamEnvironments from outpost"

trial_team=$(new_team trial)
premium_team=$(new_team premium)
send_event_until_accepted "$trial_team" trial || fail "the EventSource did not accept the request (check 4 shows why)"
send_event_until_accepted "$premium_team" premium || fail "the EventSource did not accept the request (check 4 shows why)"

name=$(wait_for_workflow "$premium_team" 90) \
  || fail "no Workflow has the team parameter $premium_team: the Sensor did not start one, or it does not copy body.team into the team parameter. Read the Sensor log"
case "$name" in
  request-environment-*) ;;
  *) fail "Workflow $name does not start with request-environment-" ;;
esac
ref=$(kubectl -n "$NS" get workflow "$name" -o jsonpath='{.spec.workflowTemplateRef.name}' 2>/dev/null)
[ "$ref" = "request-environment" ] || fail "Workflow $name does not use workflowTemplateRef request-environment"
echo "OK: the premium order started $name with the team $premium_team"

sleep 10
if [ -n "$(workflows_for_team "$trial_team")" ]; then
  fail "the tier trial started a Workflow: the Sensor must drop events whose body.tier is not standard or premium"
fi
if kubectl -n outpost get "$TE" "$trial_team" >/dev/null 2>&1; then
  fail "the tier trial created a TeamEnvironment"
fi
echo "OK: the trial order was dropped by the Sensor"

kubectl -n "$NS" delete workflow "$name" --ignore-not-found --wait=false >/dev/null 2>&1
kubectl -n outpost delete "$TE" --all --wait=false >/dev/null 2>&1
pass "premium starts request-environment with the posted team and trial is dropped"
