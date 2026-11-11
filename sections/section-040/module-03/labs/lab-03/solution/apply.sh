#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
kubectl apply -f "$DIR/solution/roles.yaml"
for attempt in $(seq 1 60); do
  if kubectl auth can-i create teamenvironments.platform.starfleet.io -n outpost --as=platform-editor --quiet && kubectl auth can-i list teamenvironments.platform.starfleet.io -n outpost --as=platform-reader --quiet && [ "$(kubectl auth can-i create teamenvironments.platform.starfleet.io -n outpost --as=platform-reader || true)" = no ]; then exit 0; fi
  sleep 2
done
echo 'Aggregation did not converge' >&2
exit 1
