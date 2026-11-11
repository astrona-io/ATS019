#!/usr/bin/env bash
# Grading for ats-019-lab-040-01-02, check 1. The fix is RBAC, not a different workflow:
#   1. the WorkflowTemplate deploy-scout exists and still runs as provisioner
#   2. it still has the two resource steps (apply Deployment, apply Service)
#   3. the ServiceAccount provisioner still exists in starfleet
set -u

NS="starfleet"
fail() { echo "FAIL: $*"; exit 1; }

kubectl -n "$NS" get workflowtemplate deploy-scout >/dev/null 2>&1 \
  || fail "the WorkflowTemplate deploy-scout does not exist. Do not delete it"
account=$(kubectl -n "$NS" get workflowtemplate deploy-scout -o jsonpath='{.spec.serviceAccountName}')
[ "$account" = "provisioner" ] || fail "deploy-scout runs as '${account}', expected provisioner. Fix the permissions of provisioner, do not change the identity"
echo "OK: deploy-scout still runs as provisioner"

actions=$(kubectl -n "$NS" get workflowtemplate deploy-scout -o jsonpath='{range .spec.templates[*]}{.resource.action}{" "}{end}')
count=$(echo "$actions" | wc -w | tr -d ' ')
[ "$count" = "2" ] || fail "deploy-scout has ${count} resource steps, expected 2 (a Deployment and a Service)"
manifests=$(kubectl -n "$NS" get workflowtemplate deploy-scout -o jsonpath='{range .spec.templates[*]}{.resource.manifest}{"\n"}{end}')
echo "$manifests" | grep -q "kind: Deployment" || fail "deploy-scout no longer applies a Deployment"
echo "$manifests" | grep -q "kind: Service" || fail "deploy-scout no longer applies a Service"
echo "OK: deploy-scout still applies a Deployment and a Service"

kubectl -n "$NS" get serviceaccount provisioner >/dev/null 2>&1 || fail "the ServiceAccount provisioner does not exist in ${NS}"
echo "OK: the ServiceAccount provisioner exists"

echo "PASS: the workflow definition is unchanged"
exit 0
