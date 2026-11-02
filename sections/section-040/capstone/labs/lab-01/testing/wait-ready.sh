#!/usr/bin/env bash
# Helper for `astrona test`: waits until the EventSource pod and the Sensor pod
# of the reference solution run again after the apply. Runs after solution/apply.sh.
# The apply replaces the Deployment, so an old pod can still be shutting down while the
# new one starts. This helper ignores pods with a deletion timestamp.
set -euo pipefail
NS=starfleet
wait_for_pod() {
  for _ in $(seq 1 90); do
    ready_pods=$(kubectl -n "$NS" get pod -l "$1" \
      -o go-template='{{range .items}}{{if not .metadata.deletionTimestamp}}{{.metadata.name}} {{range .status.containerStatuses}}{{.ready}} {{end}}{{"\n"}}{{end}}{{end}}' 2>/dev/null || true)
    if [ -n "$ready_pods" ] && ! echo "$ready_pods" | grep -q false; then
      return 0
    fi
    sleep 5
  done
  echo "pods with label $1 are not Ready" >&2
  return 1
}
wait_for_pod eventsource-name=provision
wait_for_pod sensor-name=provision
