#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`.
# Creates the missing Secret and points the Prometheus resource at the ServiceAccount
# that exists. Keep in step with solution.md.
set -euo pipefail
cd "$(dirname "$0")"

kubectl apply -f solution.yaml
kubectl -n outpost patch prometheus tenant --type merge -p '{"spec":{"serviceAccountName":"prometheus"}}'
