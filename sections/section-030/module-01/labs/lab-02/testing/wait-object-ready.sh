#!/usr/bin/env bash
# Test helper: waits until the Object reports Ready. The provider retries a failed
# reconcile with a growing delay, so this can take a few minutes.
set -euo pipefail

kubectl -n outpost wait objects.kubernetes.m.crossplane.io/scout --for=condition=Ready --timeout=420s
kubectl -n outpost wait objects.kubernetes.m.crossplane.io/scout --for=condition=Synced --timeout=60s
