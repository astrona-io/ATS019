#!/usr/bin/env bash
# Test helper: waits until the Prometheus resource reports Reconciled and Available.
set -euo pipefail

kubectl -n outpost wait --for=condition=Reconciled --timeout=180s prometheus/tenant
kubectl -n outpost wait --for=condition=Available --timeout=300s prometheus/tenant
