#!/usr/bin/env bash
# Check 7: one real order from the webhook to a Ready environment.
#   a. the grader removes old TeamEnvironments, then sends a standard order for a
#      team name it made up
#   b. the Workflow creates the TeamEnvironment with that name and spec.team
#   c. the Workflow ends as Succeeded only when status.availableReplicas is set.
#      The Composition keeps every Deployment unavailable for 20 seconds
#      (minReadySeconds), so a step without a working successCondition ends too
#      early and fails here
#   d. the TeamEnvironment is Ready and Synced and Crossplane built it
#   e. shuttle in outpost gets 200 from the scout Service
#   f. the tenant can read the environment
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

team=$(new_team order)
send_event_until_accepted "$team" standard || fail "the EventSource did not accept the order (check 4 shows why)"
name=$(wait_for_workflow "$team" 90) || fail "no Workflow started for the team $team (check 6 shows why)"
echo "OK: the order started the Workflow $name"

for _ in $(seq 1 40); do
  kubectl -n outpost get "$TE" "$team" >/dev/null 2>&1 && break
  sleep 3
done
kubectl -n outpost get "$TE" "$team" >/dev/null 2>&1 || {
  nodes=$(kubectl -n "$NS" get workflow "$name" -o jsonpath='{range .status.nodes.*}{.displayName}{": "}{.phase}{" "}{.message}{"\n"}{end}' 2>/dev/null)
  fail "the Workflow $name did not create the TeamEnvironment $team in outpost. Node status:
${nodes}"
}
spec_team=$(kubectl -n outpost get "$TE" "$team" -o jsonpath='{.spec.team}')
[ "$spec_team" = "$team" ] || fail "the TeamEnvironment has spec.team='${spec_team}', expected $team"
echo "OK: the Workflow created the TeamEnvironment $team with spec.team=$team"

phase=""
for _ in $(seq 1 100); do
  phase=$(kubectl -n "$NS" get workflow "$name" -o jsonpath='{.status.phase}' 2>/dev/null)
  case "$phase" in Succeeded|Failed|Error) break ;; esac
  sleep 3
done
case "$phase" in
  Succeeded) ;;
  Failed|Error)
    nodes=$(kubectl -n "$NS" get workflow "$name" -o jsonpath='{range .status.nodes.*}{.displayName}{": "}{.phase}{" "}{.message}{"\n"}{end}' 2>/dev/null)
    fail "the Workflow $name ended as $phase. Node status:
${nodes}" ;;
  *) fail "the Workflow $name is still '${phase}' after 5 minutes" ;;
esac
available=$(kubectl -n outpost get "$TE" "$team" -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "${available:-0}" -lt 1 ] 2>/dev/null; then
  fail "the Workflow Succeeded while status.availableReplicas of the TeamEnvironment is '${available}': the step must wait with a successCondition on status.availableReplicas"
fi
echo "OK: the Workflow Succeeded only after the environment had available replicas"

ready=""
synced=""
for _ in $(seq 1 20); do
  ready=$(kubectl -n outpost get "$TE" "$team" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
  synced=$(kubectl -n outpost get "$TE" "$team" -o jsonpath='{.status.conditions[?(@.type=="Synced")].status}' 2>/dev/null)
  [ "$ready" = "True" ] && [ "$synced" = "True" ] && break
  sleep 3
done
[ "$ready" = "True" ] || fail "the TeamEnvironment condition Ready is '${ready}', expected True"
[ "$synced" = "True" ] || fail "the TeamEnvironment condition Synced is '${synced}', expected True"
echo "OK: the TeamEnvironment is Ready and Synced"

objects=$(kubectl -n outpost get objects.kubernetes.m.crossplane.io -o name 2>/dev/null | wc -l | tr -d ' ')
[ "${objects:-0}" -ge 2 ] || fail "Crossplane created ${objects} managed resources in outpost, expected the Deployment and the Service"
echo "OK: Crossplane built the Deployment and the Service from the Composition"

code=""
for _ in $(seq 1 12); do
  code=$(kubectl -n outpost exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://scout:9898 2>/dev/null)
  [ "$code" = "200" ] && break
  sleep 5
done
[ "$code" = "200" ] || fail "a request from shuttle to http://scout:9898 returned '${code}', expected 200"
echo "OK: shuttle gets 200 from the scout Service"

kubectl -n outpost get "$TE" "$team" --as outpost-dev --as-group outpost-team >/dev/null 2>&1 \
  || fail "outpost-dev cannot read the TeamEnvironment $team"
pass "an order for $team ended with a Ready TeamEnvironment and scout answers 200"
