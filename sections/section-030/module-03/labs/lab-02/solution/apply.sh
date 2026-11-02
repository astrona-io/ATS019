#!/usr/bin/env bash
# Reference solution: apply the repaired Composition and wait until the
# existing request is Ready with two replicas.
set -euo pipefail
cd "$(dirname "$0")"

kubectl apply -f solution.yaml
kubectl -n outpost wait teamenvironment/scout-env --for=condition=Ready --timeout=600s
kubectl -n outpost rollout status deployment/scout --timeout=300s
