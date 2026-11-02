#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`. The first apply creates
# the XRD; the request in the same file fails until the XRD is Established, so
# that error is expected. The second apply creates the request.
set -euo pipefail
cd "$(dirname "$0")"
kubectl apply -f solution.yaml || true
kubectl wait xrd/probeenvironments.platform.starfleet.io --for=condition=Established --timeout=120s
kubectl wait --for=condition=Established --timeout=120s crd/probeenvironments.platform.starfleet.io
kubectl apply -f solution.yaml
