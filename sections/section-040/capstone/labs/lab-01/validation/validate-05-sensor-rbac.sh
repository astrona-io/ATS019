#!/usr/bin/env bash
# Check 5: the Sensor ServiceAccount may create Workflows in starfleet and nothing
# broad. It rejects cluster-admin, wildcards and a Sensor that is allowed to build
# the environment itself.
set -uo pipefail
NS=starfleet
SUBJECT="system:serviceaccount:$NS:operate-workflow-sa"
fail=0
pass_line() { echo "PASS: $1"; }
fail_line() { echo "FAIL: $1"; fail=1; }
can() { kubectl auth can-i "$@" --as="$SUBJECT" 2>/dev/null; }

if [ "$(can create workflows.argoproj.io -n "$NS")" = "yes" ]; then
  pass_line "operate-workflow-sa can create Workflows in $NS"
else
  fail_line "operate-workflow-sa cannot create Workflows in $NS (the Sensor log shows forbidden)"
fi
if [ "$(can create workflows.argoproj.io -n outpost)" = "no" ]; then
  pass_line "operate-workflow-sa cannot create Workflows in outpost"
else
  fail_line "operate-workflow-sa can create Workflows in outpost: use a Role in $NS, not a cluster-wide binding"
fi
if [ "$(can '*' '*' -n "$NS")" = "no" ]; then pass_line "no wildcard in $NS"; else fail_line "operate-workflow-sa has wildcard permissions in $NS"; fi
if [ "$(can '*' '*' --all-namespaces)" = "no" ]; then pass_line "no cluster-wide wildcard"; else fail_line "operate-workflow-sa is cluster-admin or has a cluster-wide wildcard"; fi
for item in secrets deployments.apps; do
  if [ "$(can get "$item" -n "$NS")" = "no" ] && [ "$(can create "$item" -n "$NS")" = "no" ]; then
    pass_line "operate-workflow-sa has no access to $item"
  else
    fail_line "operate-workflow-sa can reach $item: grant only what the trigger needs"
  fi
done
if [ "$(can create teamenvironments.platform.starfleet.io -n outpost)" = "no" ]; then
  pass_line "operate-workflow-sa cannot create TeamEnvironments"
else
  fail_line "operate-workflow-sa can create TeamEnvironments: the Workflow does that, not the Sensor"
fi
exit $fail
