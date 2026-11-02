#!/usr/bin/env bash
# Runs the WorkflowTemplate deploy-scout once and waits until it ends.
# Applied only by `astrona test`, after the reference solution.
set -euo pipefail

kubectl create -f - <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: deploy-scout-reference
  namespace: starfleet
spec:
  serviceAccountName: provisioner
  workflowTemplateRef:
    name: deploy-scout
YAML

for _ in $(seq 1 60); do
  phase=$(kubectl -n starfleet get workflow deploy-scout-reference -o jsonpath='{.status.phase}' 2>/dev/null || true)
  case "$phase" in
    Succeeded) echo "deploy-scout-reference Succeeded"; exit 0 ;;
    Failed|Error) echo "deploy-scout-reference ended as ${phase}"; exit 1 ;;
  esac
  sleep 3
done
echo "deploy-scout-reference did not finish in 3 minutes"
exit 1
