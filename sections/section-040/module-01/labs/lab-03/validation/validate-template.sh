#!/usr/bin/env bash
# Grading for ats-019-lab-040-01-03, check 2. Checks the WorkflowTemplate request-environment:
#   1. it exists in starfleet and runs as the ServiceAccount provisioner
#   2. it has the parameters name (default outpost-env) and team (default outpost)
#   3. its step is a resource template with action create
set -u

NS="starfleet"
fail() { echo "FAIL: $*"; exit 1; }
template_field() { kubectl -n "$NS" get workflowtemplate request-environment -o jsonpath="$1" 2>/dev/null; }

kubectl -n "$NS" get workflowtemplate request-environment >/dev/null 2>&1 \
  || fail "the WorkflowTemplate request-environment does not exist in the namespace ${NS}"
account=$(template_field '{.spec.serviceAccountName}')
[ "$account" = "provisioner" ] || fail "request-environment runs as '${account}', expected provisioner"
echo "OK: request-environment runs as provisioner"

name_default=$(template_field '{.spec.arguments.parameters[?(@.name=="name")].value}')
team_default=$(template_field '{.spec.arguments.parameters[?(@.name=="team")].value}')
[ "$name_default" = "outpost-env" ] || fail "the parameter name has the default '${name_default}', expected outpost-env"
[ "$team_default" = "outpost" ] || fail "the parameter team has the default '${team_default}', expected outpost"
echo "OK: the parameters name=outpost-env and team=outpost exist"

actions=$(template_field '{range .spec.templates[*]}{.resource.action}{" "}{end}')
echo " ${actions} " | grep -q " create " || fail "no template of request-environment is a resource step with action create"
echo "OK: request-environment has a resource step with action create"

echo "PASS: request-environment has the expected shape"
exit 0
