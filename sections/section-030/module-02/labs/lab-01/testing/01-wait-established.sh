#!/usr/bin/env bash
# Helper for `astrona test`: waits until the generated CRD is Established and
# the request first-probe is stored.
set -euo pipefail
kubectl wait --for=condition=Established --timeout=120s crd/probeenvironments.platform.starfleet.io
kubectl -n outpost get probeenvironment first-probe >/dev/null
