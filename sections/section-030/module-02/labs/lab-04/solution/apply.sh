#!/usr/bin/env bash
# Create the tenant request, then extend the existing Composition.
set -euo pipefail
cd "$(dirname "$0")"
kubectl apply -f teamenvironment-outpost-probe.yaml
kubectl apply -f solution.yaml
