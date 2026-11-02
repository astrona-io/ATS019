#!/usr/bin/env bash
# Grading for ats-019-lab-040-01, check 3. Checks the Workflow onboard-drifter that the
# learner submitted:
#   1. it uses workflowTemplateRef onboard-team with team=drifter and size=large
#   2. it ended as Succeeded
#   3. a step printed "onboarding drifter with size large"
#   4. announce started after both checks finished (when the node times are readable)
set -u

NS="starfleet"
fail() { echo "FAIL: $*"; exit 1; }
workflow_field() { kubectl -n "$NS" get workflow onboard-drifter -o jsonpath="$1" 2>/dev/null; }

# --- 1. the Workflow and its arguments ------------------------------------------------
kubectl -n "$NS" get workflow onboard-drifter >/dev/null 2>&1 \
  || fail "the Workflow onboard-drifter does not exist in the namespace ${NS}"
reference=$(workflow_field '{.spec.workflowTemplateRef.name}')
[ "$reference" = "onboard-team" ] || fail "onboard-drifter does not use workflowTemplateRef onboard-team (found '${reference}')"
team=$(workflow_field '{.spec.arguments.parameters[?(@.name=="team")].value}')
size=$(workflow_field '{.spec.arguments.parameters[?(@.name=="size")].value}')
[ "$team" = "drifter" ] || fail "onboard-drifter sets team='${team}', expected drifter"
[ "$size" = "large" ] || fail "onboard-drifter sets size='${size}', expected large"
echo "OK: onboard-drifter uses onboard-team with team=drifter and size=large"

# --- 2. the phase ---------------------------------------------------------------------
phase=""
for _ in $(seq 1 60); do
  phase=$(workflow_field '{.status.phase}')
  case "$phase" in Succeeded|Failed|Error) break ;; esac
  sleep 3
done
[ "$phase" = "Succeeded" ] || fail "onboard-drifter is in the phase '${phase:-none}', expected Succeeded"
echo "OK: onboard-drifter Succeeded"

# --- 3. the output --------------------------------------------------------------------
logs=$(kubectl -n "$NS" logs -l "workflows.argoproj.io/workflow=onboard-drifter" -c main --max-log-requests=10 --tail=-1 2>&1)
echo "$logs" | grep -Fxq "onboarding drifter with size large" \
  || fail "no step of onboard-drifter printed exactly 'onboarding drifter with size large'"
echo "OK: a step printed 'onboarding drifter with size large'"

# --- 4. the order of the tasks --------------------------------------------------------
nodes=$(workflow_field '{range .status.nodes.*}{.displayName}{" "}{.startedAt}{" "}{.finishedAt}{"\n"}{end}')
announce_start=$(echo "$nodes" | awk '$1=="announce"{print $2}')
team_end=$(echo "$nodes" | awk '$1=="check-team"{print $3}')
size_end=$(echo "$nodes" | awk '$1=="check-size"{print $3}')
if [ -n "$announce_start" ] && [ -n "$team_end" ] && [ -n "$size_end" ]; then
  # Times are in the form 2026-01-02T03:04:05Z, so a text comparison is a time comparison.
  { [ "$announce_start" \> "$team_end" ] || [ "$announce_start" = "$team_end" ]; } \
    || fail "announce started at ${announce_start}, before check-team ended at ${team_end}"
  { [ "$announce_start" \> "$size_end" ] || [ "$announce_start" = "$size_end" ]; } \
    || fail "announce started at ${announce_start}, before check-size ended at ${size_end}"
  echo "OK: announce started after both checks ended"
else
  echo "NOTE: could not read the node times, the task order is not checked here"
fi

echo "PASS: onboard-drifter ran the parameterized DAG"
exit 0
