#!/usr/bin/env bash
# Reference solution: replaces the Sensor so the data filter reads body.tier.
# Used only by `astrona test`.
set -euo pipefail
cd "$(dirname "$0")"
kubectl apply -f solution.yaml
