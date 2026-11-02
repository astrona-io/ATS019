#!/usr/bin/env bash
# Grading for ats-019-lab-040-03, check 1. Asks the API server what the ServiceAccount
# starfleet/provisioner may do:
#   1. in outpost it may get, list, watch and create TeamEnvironments (a step that
#      waits needs all four)
#   2. it may not delete or update them, and may not write their status (the
#      controller does that, not the workflow)
#   3. it may not create Deployments in outpost
#   4. it has no wildcard power
set -u

SUBJECT="system:serviceaccount:starfleet:provisioner"
fail() { echo "FAIL: $*"; exit 1; }
can() { kubectl auth can-i "$@" --as="$SUBJECT" 2>/dev/null; }

for verb in get list watch create; do
  [ "$(can "$verb" teamenvironments.platform.starfleet.io -n outpost)" = "yes" ] \
    || fail "provisioner cannot ${verb} teamenvironments in outpost"
done
echo "OK: provisioner can get, list, watch and create TeamEnvironments in outpost"

for verb in delete update patch deletecollection; do
  [ "$(can "$verb" teamenvironments.platform.starfleet.io -n outpost)" = "no" ] \
    || fail "provisioner can ${verb} teamenvironments in outpost. Grant only get, list, watch and create"
done
[ "$(can patch teamenvironments.platform.starfleet.io/status -n outpost)" = "no" ] \
  || fail "provisioner can write the status of a TeamEnvironment. The status belongs to the controller"
echo "OK: provisioner cannot delete, update or write the status"

[ "$(can create deployments.apps -n outpost)" = "no" ] || fail "provisioner can create Deployments in outpost. It needs only TeamEnvironments"
[ "$(can '*' '*' --all-namespaces)" = "no" ] || fail "provisioner can do everything. Do not use cluster-admin or wildcards"
echo "OK: provisioner has nothing beyond TeamEnvironments"

echo "PASS: provisioner has the permissions the waiting step needs"
exit 0
