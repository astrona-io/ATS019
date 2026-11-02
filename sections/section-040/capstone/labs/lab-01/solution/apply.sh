#!/usr/bin/env bash
# Reference end state. Applied only by `astrona test`.
set -euo pipefail
cd "$(dirname "$0")"
kubectl apply -f solution.yaml
