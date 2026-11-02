#!/usr/bin/env bash
# Test helper: waits until the operator has acted on the new spec and the pod is back.
set -euo pipefail

kubectl -n starfleet wait --for=condition=Reconciled --timeout=180s prometheus/starfleet
kubectl -n starfleet wait --for=condition=Available --timeout=300s prometheus/starfleet
