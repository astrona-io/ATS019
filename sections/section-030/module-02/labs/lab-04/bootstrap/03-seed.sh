#!/usr/bin/env bash
# Record a live baseline before the learner adds the client Service.
set -euo pipefail
cd "$(dirname "$0")/.."
kubectl apply -f manifests/xrd-teamenvironment.yaml
kubectl wait xrd/teamenvironments.platform.starfleet.io --for=condition=Established --timeout=120s
kubectl apply -f manifests/composition-scout-stateful.yaml
kubectl apply -f manifests/teamenvironment-outpost-scout.yaml
kubectl -n outpost wait teamenvironment/outpost-scout --for=condition=Ready --timeout=300s
kubectl -n outpost rollout status statefulset/outpost-scout --timeout=240s
XR_UID="$(kubectl -n outpost get teamenvironment outpost-scout -o jsonpath='{.metadata.uid}')"
STS_UID="$(kubectl -n outpost get statefulset outpost-scout -o jsonpath='{.metadata.uid}')"
HEAD_UID="$(kubectl -n outpost get service outpost-scout-pods -o jsonpath='{.metadata.uid}')"
REVISION="$(kubectl -n outpost get teamenvironment outpost-scout -o jsonpath='{.spec.crossplane.compositionRevisionRef.name}')"
HEAD_TEMPLATE="$(kubectl get composition scout-stateful -o jsonpath='{.spec.pipeline[0].input.resources[0]}')"
STS_TEMPLATE="$(kubectl get composition scout-stateful -o jsonpath='{.spec.pipeline[0].input.resources[1]}')"
kubectl -n outpost get service outpost-scout >/dev/null 2>&1 && exit 1
kubectl -n starfleet create configmap lab-state \
  --from-literal=xr-uid="$XR_UID" --from-literal=sts-uid="$STS_UID" \
  --from-literal=head-uid="$HEAD_UID" --from-literal=revision="$REVISION" \
  --from-literal=head-template="$HEAD_TEMPLATE" --from-literal=sts-template="$STS_TEMPLATE" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n starfleet patch configmap lab-state --type=merge -p '{"immutable":true}'
