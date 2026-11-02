#!/usr/bin/env bash
# Grading for ats-019-lab-040-03, check 3. The grader plays the controller.
#   Run 1 (Ready):
#     a. a TeamEnvironment with the requested name and team appears in outpost
#     b. 20 seconds later the Workflow is still Running (a step without a
#        successCondition would already have Succeeded)
#     c. after status.phase=Ready the Workflow ends as Succeeded
#   Run 2 (Failed):
#     d. after status.phase=Failed the Workflow ends as Failed
set -u

NS="starfleet"
fail() { echo "FAIL: $*"; exit 1; }
phase_of() { kubectl -n "$NS" get workflow "$1" -o jsonpath='{.status.phase}' 2>/dev/null; }

wait_for_phase() {
  local name="$1" wanted="$2" phase=""
  for _ in $(seq 1 40); do
    phase=$(phase_of "$name")
    [ "$phase" = "$wanted" ] && return 0
    case "$phase" in Succeeded|Failed|Error) [ "$phase" != "$wanted" ] && break ;; esac
    sleep 3
  done
  echo "$phase"
  return 1
}

start_request() {
  local workflow="$1" object="$2" team="$3"
  kubectl -n "$NS" delete workflow "$workflow" --ignore-not-found --wait=true >/dev/null 2>&1
  kubectl -n outpost delete teamenvironment "$object" --ignore-not-found --wait=true >/dev/null 2>&1
  kubectl create -f - >/dev/null <<YAML || fail "could not create the Workflow ${workflow}"
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: ${workflow}
  namespace: ${NS}
spec:
  serviceAccountName: provisioner
  workflowTemplateRef:
    name: request-environment
  arguments:
    parameters:
      - name: name
        value: ${object}
      - name: team
        value: ${team}
YAML
  for _ in $(seq 1 40); do
    kubectl -n outpost get teamenvironment "$object" >/dev/null 2>&1 && return 0
    case "$(phase_of "$workflow")" in Failed|Error) break ;; esac
    sleep 3
  done
  local messages
  messages=$(kubectl -n "$NS" get workflow "$workflow" -o jsonpath='{range .status.nodes.*}{.displayName}{": "}{.phase}{" "}{.message}{"\n"}{end}' 2>/dev/null)
  fail "the Workflow ${workflow} did not create the TeamEnvironment ${object} in outpost. Phase: '$(phase_of "$workflow")'. Node status:
${messages}"
}

set_phase() {
  kubectl -n outpost patch teamenvironment "$1" --subresource=status --type=merge \
    -p "{\"status\":{\"phase\":\"$2\"}}" >/dev/null 2>&1 || fail "could not set status.phase=$2 on $1"
}

kubectl -n "$NS" get workflowtemplate request-environment >/dev/null 2>&1 \
  || fail "the WorkflowTemplate request-environment does not exist in the namespace ${NS}"

# --- Run 1: Ready ----------------------------------------------------------------------
start_request grade-ready grade-ready-env graders
team=$(kubectl -n outpost get teamenvironment grade-ready-env -o jsonpath='{.spec.team}')
[ "$team" = "graders" ] || fail "the TeamEnvironment has spec.team='${team}', expected graders. Use the parameter team"
echo "OK: the Workflow created the TeamEnvironment grade-ready-env with spec.team=graders"

sleep 20
phase=$(phase_of grade-ready)
[ "$phase" = "Running" ] || fail "20 seconds after the object was created, the Workflow is '${phase}', expected Running. The step must wait for status.phase == Ready"
echo "OK: the Workflow keeps waiting while status.phase is empty"

set_phase grade-ready-env Ready
result=$(wait_for_phase grade-ready Succeeded) || fail "after status.phase=Ready the Workflow is '${result}', expected Succeeded. Check the successCondition and the verbs watch and list"
echo "OK: the Workflow Succeeded after status.phase=Ready"

# --- Run 2: Failed ---------------------------------------------------------------------
start_request grade-failed grade-failed-env graders
set_phase grade-failed-env Failed
result=$(wait_for_phase grade-failed Failed) || fail "after status.phase=Failed the Workflow is '${result}', expected Failed. Add a failureCondition"
echo "OK: the Workflow Failed after status.phase=Failed"

kubectl -n "$NS" delete workflow grade-ready grade-failed --ignore-not-found --wait=false >/dev/null 2>&1
kubectl -n outpost delete teamenvironment grade-ready-env grade-failed-env --ignore-not-found --wait=false >/dev/null 2>&1
echo "PASS: the resource step waits for Ready and fails on Failed"
exit 0
