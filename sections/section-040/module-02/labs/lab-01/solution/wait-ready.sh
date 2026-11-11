#!/usr/bin/env bash
# Wait for pods, then prove the complete event-to-Workflow path.
set -euo pipefail
NS=starfleet
wait_for_pod() {
  for i in $(seq 1 90); do
    if kubectl -n "$NS" get pod -l "$1" -o name 2>/dev/null | grep -q .; then
      kubectl -n "$NS" wait --for=condition=Ready pod -l "$1" --timeout=180s
      return 0
    fi
    sleep 5
  done
  echo "no pod with label $1" >&2
  return 1
}
wait_for_pod eventsource-name=provision
wait_for_pod sensor-name=provision

# Pod readiness does not prove that the Sensor has subscribed to JetStream.
# These disposable requests exercise only the lab's practice WorkflowTemplate.
probe="readiness-$(date +%s)-$RANDOM"
deadline=$((SECONDS + 300))
while (( SECONDS < deadline )); do
  kubectl -n "$NS" exec deploy/shuttle -- curl -fsS --max-time 10 \
    -X POST -H 'Content-Type: application/json' \
    -d "{\"team\":\"$probe\",\"tier\":\"standard\"}" \
    http://provision-eventsource-svc.starfleet.svc:12000/provision >/dev/null || true
  sleep 5
  workflows=$(kubectl -n "$NS" get workflows -o jsonpath='{range .items[*]}{.spec.workflowTemplateRef.name}{" "}{.spec.arguments.parameters[?(@.name=="team")].value}{"\n"}{end}')
  if awk -v team="$probe" '$1 == "provision-environment" && $2 == team { found=1 } END { exit !found }' <<< "$workflows"; then
    echo 'PASS: the Sensor delivered a readiness event to the practice WorkflowTemplate'
    exit 0
  fi
done
echo 'FAIL: no Workflow received the readiness event within five minutes' >&2
exit 1
