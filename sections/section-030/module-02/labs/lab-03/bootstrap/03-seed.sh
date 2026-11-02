#!/usr/bin/env bash
# Creates the starting state: the TeamEnvironment XRD, the faulty Composition,
# one request in outpost and the shuttle client. It also records the UID of
# the request, so the grader can tell whether the request was deleted and
# created again. It does not wait for the request to be Ready: the faulty
# Composition decides what happens.
set -euo pipefail
cd "$(dirname "$0")/.."

kubectl apply -f manifests/xrd-teamenvironment.yaml >/dev/null
kubectl wait xrd/teamenvironments.platform.starfleet.io --for=condition=Established --timeout=120s
kubectl apply -f manifests/composition-teamenvironment.yaml >/dev/null
kubectl apply -f manifests/teamenvironment-outpost-env.yaml >/dev/null
kubectl apply -f manifests/deployment-shuttle.yaml >/dev/null
XR_UID="$(kubectl -n outpost get teamenvironment outpost-env -o jsonpath='{.metadata.uid}')"
kubectl -n starfleet create configmap lab-state \
  --from-literal=xr-uid="$XR_UID" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl -n outpost rollout status deploy/shuttle --timeout=240s
