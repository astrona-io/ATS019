#!/usr/bin/env bash
# Check 3: the WorkflowTemplate request-environment has the required shape. The
# run itself is graded in check 7.
set -uo pipefail
NS=starfleet
fail=0
pass_line() { echo "PASS: $1"; }
fail_line() { echo "FAIL: $1"; fail=1; }
field() { kubectl -n "$NS" get workflowtemplate request-environment -o jsonpath="$1" 2>/dev/null; }

if ! kubectl -n "$NS" get workflowtemplate request-environment >/dev/null 2>&1; then
  echo "FAIL: the WorkflowTemplate request-environment does not exist in $NS"
  exit 1
fi
pass_line "the WorkflowTemplate request-environment exists"

account=$(field '{.spec.serviceAccountName}')
if [ "$account" = "provisioner" ]; then
  pass_line "request-environment runs as provisioner"
else
  fail_line "request-environment runs as '${account}', expected provisioner"
fi

if [ -n "$(field '{.spec.arguments.parameters[?(@.name=="team")].name}')" ]; then
  pass_line "request-environment has the input parameter team"
else
  fail_line "request-environment has no input parameter named team"
fi

actions=$(field '{range .spec.templates[*]}{.resource.action}{" "}{end}')
if echo " ${actions} " | grep -q " create "; then
  pass_line "request-environment has a resource step with action create"
else
  fail_line "no template of request-environment is a resource step with action create"
fi

conditions=$(field '{range .spec.templates[*]}{.resource.successCondition}{"\n"}{end}' | tr -d '[:space:]')
if [ -n "$conditions" ]; then
  pass_line "the resource step has a successCondition"
else
  fail_line "the resource step has no successCondition: without it the step ends right after create"
fi

manifest=$(field '{range .spec.templates[*]}{.resource.manifest}{"\n"}{end}')
if echo "$manifest" | grep -q 'kind: TeamEnvironment' && echo "$manifest" | grep -q 'namespace: outpost'; then
  pass_line "the step creates a TeamEnvironment in outpost"
else
  fail_line "the step does not create a TeamEnvironment in the namespace outpost"
fi
if echo "$manifest" | grep -Eq '(workflow|inputs)\.parameters\.team'; then
  pass_line "the manifest uses the parameter team"
else
  fail_line "the manifest does not use the parameter team: a fixed name serves only one team"
fi
exit $fail
