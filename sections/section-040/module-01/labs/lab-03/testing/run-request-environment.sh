#!/usr/bin/env bash
# Runs request-environment once, writes status.phase Ready like a controller
# would, and waits until the Workflow Succeeded. Applied only by `astrona test`.
set -euo pipefail

kubectl create -f - <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: request-environment-reference
  namespace: starfleet
spec:
  serviceAccountName: provisioner
  workflowTemplateRef:
    name: request-environment
YAML

for _ in $(seq 1 60); do
  kubectl -n outpost get teamenvironment outpost-env >/dev/null 2>&1 && break
  sleep 3
done
kubectl -n outpost patch teamenvironment outpost-env --subresource=status --type=merge \
  -p '{"status":{"phase":"Ready"}}'

for _ in $(seq 1 60); do
  phase=$(kubectl -n starfleet get workflow request-environment-reference -o jsonpath='{.status.phase}' 2>/dev/null || true)
  case "$phase" in
    Succeeded) echo "request-environment-reference Succeeded"; exit 0 ;;
    Failed|Error) echo "request-environment-reference ended as ${phase}"; exit 1 ;;
  esac
  sleep 3
done
echo "request-environment-reference did not finish in 3 minutes"
exit 1
