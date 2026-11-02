#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`.
# Gives the existing Role the verbs the provider needs. Keep in step with solution.md.
set -euo pipefail
cd "$(dirname "$0")"

kubectl apply -f solution.yaml
