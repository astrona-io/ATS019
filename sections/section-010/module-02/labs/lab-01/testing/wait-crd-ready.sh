#!/usr/bin/env bash
# Test helper: waits until the CRD is Established and serves v1.
set -euo pipefail

kubectl wait --for=condition=Established --timeout=60s crd/teamenvironments.platform.starfleet.io
for _ in $(seq 1 30); do
  kubectl -n outpost get --raw /apis/platform.starfleet.io/v1/namespaces/outpost/teamenvironments >/dev/null 2>&1 && exit 0
  sleep 2
done
echo "the v1 endpoint did not appear" >&2
exit 1
