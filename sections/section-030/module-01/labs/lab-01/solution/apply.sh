#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`.
# Installs provider-kubernetes 1.4.1 with a fixed ServiceAccount name. Keep in step with solution.md.
set -euo pipefail
cd "$(dirname "$0")"

kubectl apply -f solution.yaml
