#!/usr/bin/env bash
# Grading for ats-019-lab-040-02, check 2. Asks the API server what the ServiceAccount
# starfleet/provisioner may do:
#   1. in outpost it may get, create and patch Deployments and Services
#   2. in outpost it may not delete them, and may not touch Secrets
#   3. it may not create Deployments in default or starfleet
#   4. it has no wildcard power (cluster-admin or "*" on "*")
# The plausible wrong fix, a cluster-admin binding, fails checks 2 to 4.
set -u

SUBJECT="system:serviceaccount:starfleet:provisioner"
fail() { echo "FAIL: $*"; exit 1; }
can() { kubectl auth can-i "$@" --as="$SUBJECT" 2>/dev/null; }

for resource in deployments.apps services; do
  for verb in get create patch; do
    [ "$(can "$verb" "$resource" -n outpost)" = "yes" ] \
      || fail "provisioner cannot ${verb} ${resource} in outpost"
  done
done
echo "OK: provisioner can get, create and patch Deployments and Services in outpost"

for resource in deployments.apps services secrets; do
  [ "$(can delete "$resource" -n outpost)" = "no" ] \
    || fail "provisioner can delete ${resource} in outpost. Grant only the verbs the steps use"
done
[ "$(can create secrets -n outpost)" = "no" ] || fail "provisioner can create Secrets in outpost"
[ "$(can get secrets -n outpost)" = "no" ] || fail "provisioner can read Secrets in outpost"
echo "OK: provisioner cannot delete workloads or touch Secrets in outpost"

for namespace in default starfleet; do
  [ "$(can create deployments.apps -n "$namespace")" = "no" ] \
    || fail "provisioner can create Deployments in ${namespace}. The permission belongs in outpost only"
done
echo "OK: provisioner cannot create Deployments outside outpost"

[ "$(can '*' '*' --all-namespaces)" = "no" ] || fail "provisioner can do everything in every namespace. Do not use cluster-admin or wildcards"
echo "OK: provisioner has no wildcard permission"

echo "PASS: provisioner has exactly the permissions the steps need"
exit 0
