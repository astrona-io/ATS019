#!/usr/bin/env bash
# Creates the two namespaces and installs the TeamEnvironment API as a plain
# CRD. There is no RBAC for the tenant identity at the start.
set -euo pipefail
cd "$(dirname "$0")/.."

kubectl create namespace starfleet --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl create namespace outpost --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl apply -f manifests/crd-teamenvironment.yaml >/dev/null
kubectl wait --for=condition=Established --timeout=60s \
  crd/teamenvironments.platform.starfleet.io
