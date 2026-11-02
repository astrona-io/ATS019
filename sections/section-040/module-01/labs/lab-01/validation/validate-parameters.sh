#!/usr/bin/env bash
# Grading for ats-019-lab-040-01, check 2. Runs the WorkflowTemplate onboard-team twice
# with its own Workflows and reads the output of the steps:
#   1. no arguments: a step prints "onboarding outpost with size small"
#   2. team=graders, size=medium: a step prints "onboarding graders with size medium"
# A template that hard-codes the values fails the second run.
set -u

NS="starfleet"
fail() { echo "FAIL: $*"; exit 1; }

wait_for_end() {
  local name="$1" phase=""
  for _ in $(seq 1 60); do
    phase=$(kubectl -n "$NS" get workflow "$name" -o jsonpath='{.status.phase}' 2>/dev/null)
    case "$phase" in
      Succeeded|Failed|Error) echo "$phase"; return 0 ;;
    esac
    sleep 3
  done
  echo "${phase:-Unknown}"
}

run_workflow() {
  local name="$1" arguments="$2" expected_line="$3"
  kubectl -n "$NS" delete workflow "$name" --ignore-not-found --wait=true >/dev/null 2>&1
  kubectl create -f - >/dev/null <<YAML || fail "could not create the Workflow ${name}"
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: ${name}
  namespace: ${NS}
spec:
  workflowTemplateRef:
    name: onboard-team
${arguments}
YAML
  phase=$(wait_for_end "$name")
  [ "$phase" = "Succeeded" ] || fail "the Workflow ${name} ended as ${phase}, expected Succeeded. Read its node messages and the pod logs"
  logs=$(kubectl -n "$NS" logs -l "workflows.argoproj.io/workflow=${name}" -c main --max-log-requests=10 --tail=-1 2>&1)
  echo "$logs" | grep -Fxq "$expected_line" \
    || fail "no step of ${name} printed exactly '${expected_line}'. The parameters must reach the announce step"
  echo "OK: ${name} Succeeded and printed '${expected_line}'"
}

kubectl -n "$NS" get workflowtemplate onboard-team >/dev/null 2>&1 \
  || fail "the WorkflowTemplate onboard-team does not exist in the namespace ${NS}"

run_workflow grade-defaults "" "onboarding outpost with size small"
run_workflow grade-override "  arguments:
    parameters:
      - name: team
        value: graders
      - name: size
        value: medium" "onboarding graders with size medium"

kubectl -n "$NS" delete workflow grade-defaults grade-override --ignore-not-found --wait=false >/dev/null 2>&1
echo "PASS: the template takes its values from the parameters"
exit 0
