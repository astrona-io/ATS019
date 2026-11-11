#!/usr/bin/env bash
# Grading for ats-019-lab-040-01-02, check 3. Removes the scout objects, runs the
# WorkflowTemplate deploy-scout in a new Workflow and checks the result:
#   1. the Workflow ends as Succeeded
#   2. the Deployment scout (podinfo 6.15.0) and the Service scout (port 9898) exist in outpost
#   3. the Deployment becomes Available
set -u

NS="starfleet"
WORKFLOW="grade-deploy-scout"
fail() { echo "FAIL: $*"; exit 1; }

kubectl -n outpost delete deployment scout --ignore-not-found --wait=true >/dev/null 2>&1
kubectl -n outpost delete service scout --ignore-not-found --wait=true >/dev/null 2>&1
kubectl -n "$NS" delete workflow "$WORKFLOW" --ignore-not-found --wait=true >/dev/null 2>&1

kubectl create -f - >/dev/null <<YAML || fail "could not create the Workflow ${WORKFLOW}"
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: ${WORKFLOW}
  namespace: ${NS}
spec:
  serviceAccountName: provisioner
  workflowTemplateRef:
    name: deploy-scout
YAML

phase=""
for _ in $(seq 1 60); do
  phase=$(kubectl -n "$NS" get workflow "$WORKFLOW" -o jsonpath='{.status.phase}' 2>/dev/null)
  case "$phase" in Succeeded|Failed|Error) break ;; esac
  sleep 3
done
if [ "$phase" != "Succeeded" ]; then
  messages=$(kubectl -n "$NS" get workflow "$WORKFLOW" -o jsonpath='{range .status.nodes.*}{.displayName}{": "}{.phase}{" "}{.message}{"\n"}{end}' 2>/dev/null)
  fail "a new Workflow from deploy-scout ended as '${phase:-none}', expected Succeeded. Node status:
${messages}"
fi
echo "OK: a new Workflow from deploy-scout Succeeded"

image=$(kubectl -n outpost get deployment scout -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
[ "$image" = "ghcr.io/stefanprodan/podinfo:6.15.0" ] || fail "the Deployment scout is missing or uses the image '${image}'"
port=$(kubectl -n outpost get service scout -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)
[ "$port" = "9898" ] || fail "the Service scout is missing or uses the port '${port}', expected 9898"
echo "OK: the Deployment scout and the Service scout exist in outpost"

kubectl -n outpost wait --for=condition=Available deployment/scout --timeout=120s >/dev/null 2>&1 \
  || fail "the Deployment scout did not become Available in 2 minutes"
echo "OK: the Deployment scout is Available"

kubectl -n "$NS" delete workflow "$WORKFLOW" --ignore-not-found --wait=false >/dev/null 2>&1
echo "PASS: the provisioning workflow succeeds with least privilege"
exit 0
