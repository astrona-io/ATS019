#!/usr/bin/env bash
# Submits the Workflow onboard-drifter from the reference WorkflowTemplate and
# waits until it ends. Applied only by `astrona test`.
set -euo pipefail

kubectl create -f - <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: onboard-drifter
  namespace: starfleet
spec:
  workflowTemplateRef:
    name: onboard-team
  arguments:
    parameters:
      - name: team
        value: drifter
      - name: size
        value: large
YAML

for _ in $(seq 1 60); do
  phase=$(kubectl -n starfleet get workflow onboard-drifter -o jsonpath='{.status.phase}' 2>/dev/null || true)
  case "$phase" in
    Succeeded) echo "onboard-drifter Succeeded"; exit 0 ;;
    Failed|Error) echo "onboard-drifter ended as ${phase}"; exit 1 ;;
  esac
  sleep 3
done
echo "onboard-drifter did not finish in 3 minutes"
exit 1
