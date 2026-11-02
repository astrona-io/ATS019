#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`. Keep in step with solution.md.
set -euo pipefail
cd "$(dirname "$0")"

kubectl apply -f solution.yaml
kubectl -n starfleet patch job probe-cleanup --type=merge -p '{"spec":{"suspend":false}}'
