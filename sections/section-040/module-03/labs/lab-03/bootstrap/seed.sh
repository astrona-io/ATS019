#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
kubectl create namespace outpost
kubectl create namespace starfleet
kubectl apply -f "$DIR/crd.yaml"
kubectl wait --for=condition=Established crd/teamenvironments.platform.starfleet.io --timeout=60s
kubectl -n outpost create rolebinding platform-edit --clusterrole=edit --user=platform-editor
kubectl -n outpost create rolebinding platform-view --clusterrole=view --user=platform-reader
kubectl -n outpost get rolebindings platform-edit platform-view -o json > "$DIR/bindings.json"
