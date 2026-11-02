#!/usr/bin/env bash
# Test helper: waits for the operator to settle and for the cleanup Job to finish.
set -euo pipefail

kubectl -n outpost wait --for=condition=Available --timeout=240s prometheus/outpost-metrics
kubectl -n outpost wait --for=condition=Complete --timeout=180s job/scout-cleanup
