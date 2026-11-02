#!/usr/bin/env bash
# Check 2: the ServiceAccount starfleet/provisioner can create a TeamEnvironment in
# outpost and wait for it, and nothing more. It rejects cluster-admin, wildcards
# and a Role that also lets the Workflow change or remove environments.
set -uo pipefail
SUBJECT="system:serviceaccount:starfleet:provisioner"
TE=teamenvironments.platform.starfleet.io
fail=0

pass_line() { echo "PASS: $1"; }
fail_line() { echo "FAIL: $1"; fail=1; }
can() { kubectl auth can-i "$@" --as="$SUBJECT" 2>/dev/null; }

for verb in get list watch create; do
  if [ "$(can "$verb" "$TE" -n outpost)" = "yes" ]; then
    pass_line "provisioner can $verb teamenvironments in outpost"
  else
    fail_line "provisioner cannot $verb teamenvironments in outpost (a step that waits needs get, list and watch)"
  fi
done

for verb in update patch delete deletecollection; do
  if [ "$(can "$verb" "$TE" -n outpost)" = "no" ]; then
    pass_line "provisioner cannot $verb teamenvironments"
  else
    fail_line "provisioner can $verb teamenvironments: the Workflow only creates and watches"
  fi
done

if [ "$(can patch "$TE/status" -n outpost)" = "no" ]; then
  pass_line "provisioner cannot write the status of a TeamEnvironment"
else
  fail_line "provisioner can write the status of a TeamEnvironment: the status belongs to Crossplane"
fi

for item in deployments.apps services secrets; do
  if [ "$(can create "$item" -n outpost)" = "no" ]; then
    pass_line "provisioner cannot create $item in outpost"
  else
    fail_line "provisioner can create $item in outpost: Crossplane builds those, the Workflow does not"
  fi
done

if [ "$(can create "$TE" -n default)" = "no" ]; then
  pass_line "provisioner cannot create teamenvironments outside outpost"
else
  fail_line "provisioner can create teamenvironments in other namespaces: use a Role in outpost"
fi

if [ "$(can '*' '*' --all-namespaces)" = "no" ]; then
  pass_line "provisioner has no wildcard power"
else
  fail_line "provisioner can do everything: do not use cluster-admin or wildcards"
fi

if [ "$(can create workflowtaskresults.argoproj.io -n starfleet)" = "yes" ]; then
  pass_line "provisioner can still report step results in starfleet"
else
  fail_line "provisioner cannot create workflowtaskresults in starfleet: do not remove the Role that the setup created"
fi
exit $fail
