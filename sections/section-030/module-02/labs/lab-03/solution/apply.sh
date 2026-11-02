#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`: replaces the Composition.
set -euo pipefail
cd "$(dirname "$0")"
kubectl apply -f solution.yaml
