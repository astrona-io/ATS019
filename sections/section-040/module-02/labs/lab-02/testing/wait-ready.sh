#!/usr/bin/env bash
# Helper for `astrona test`: waits until the Sensor pod has been replaced by the
# corrected Sensor and every EventSource and Sensor pod is ready.
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
sleep 10
wait_for_pod sensor-name=provision
