#!/usr/bin/env bash
# Grading for ats-019-lab-040-01, check 1. Checks the WorkflowTemplate onboard-team:
#   1. it exists in starfleet with the parameters team=outpost and size=small
#   2. its entrypoint is a dag template with the tasks check-team, check-size, announce
#   3. announce depends on both checks
#   4. neither check depends on anything, so they can run at the same time
set -u

NS="starfleet"
fail() { echo "FAIL: $*"; exit 1; }
jsonpath() { kubectl -n "$NS" get workflowtemplate onboard-team -o jsonpath="$1" 2>/dev/null; }

# --- 1. the template and its default parameters ---------------------------------------
kubectl -n "$NS" get workflowtemplate onboard-team >/dev/null 2>&1 \
  || fail "the WorkflowTemplate onboard-team does not exist in the namespace ${NS}"
team_default=$(jsonpath '{.spec.arguments.parameters[?(@.name=="team")].value}')
size_default=$(jsonpath '{.spec.arguments.parameters[?(@.name=="size")].value}')
[ "$team_default" = "outpost" ] || fail "the parameter team has the default '${team_default}', expected outpost"
[ "$size_default" = "small" ] || fail "the parameter size has the default '${size_default}', expected small"
echo "OK: onboard-team has the parameters team=outpost and size=small"

# --- 2. the entrypoint is a DAG with the three tasks ---------------------------------
entry=$(jsonpath '{.spec.entrypoint}')
[ -n "$entry" ] || fail "the template has no entrypoint"
tasks=$(jsonpath "{.spec.templates[?(@.name==\"${entry}\")].dag.tasks[*].name}")
[ -n "$tasks" ] || fail "the entrypoint template '${entry}' is not a dag template. Use a dag, not steps"
for task in check-team check-size announce; do
  echo " ${tasks} " | grep -q " ${task} " || fail "the dag has no task named ${task} (found: ${tasks})"
done
echo "OK: the entrypoint ${entry} is a dag with the tasks check-team, check-size and announce"

# --- 3. announce depends on both checks ----------------------------------------------
task_field() {
  kubectl -n "$NS" get workflowtemplate onboard-team \
    -o jsonpath="{.spec.templates[?(@.name==\"${entry}\")].dag.tasks[?(@.name==\"$1\")].$2}" 2>/dev/null
}
announce_deps="$(task_field announce dependencies) $(task_field announce depends)"
echo "$announce_deps" | grep -q "check-team" || fail "announce does not depend on check-team"
echo "$announce_deps" | grep -q "check-size" || fail "announce does not depend on check-size"
echo "OK: announce waits for check-team and check-size"

# --- 4. the checks are independent ---------------------------------------------------
for task in check-team check-size; do
  deps="$(task_field "$task" dependencies)$(task_field "$task" depends)"
  [ -z "$deps" ] || fail "${task} depends on ${deps}. The two checks must be able to run at the same time"
done
echo "OK: check-team and check-size have no dependencies"

echo "PASS: onboard-team is a parameterized DAG"
exit 0
