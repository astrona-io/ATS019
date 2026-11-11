#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
kubectl -n outpost create rolebinding platform-edit --clusterrole=edit --user=platform-editor
kubectl -n outpost create rolebinding platform-view --clusterrole=view --user=platform-reader
kubectl -n outpost get rolebindings platform-edit platform-view -o json > "$DIR/testing/bindings.json"
kubectl get namespace starfleet >/dev/null 2>&1 || kubectl create namespace starfleet
kubectl apply -f "$DIR/testing/teamenvironment-roles.yaml"
for attempt in $(seq 1 60); do
  if kubectl auth can-i create teamenvironments.platform.starfleet.io -n outpost --as=platform-editor --quiet && kubectl auth can-i list teamenvironments.platform.starfleet.io -n outpost --as=platform-reader --quiet; then break; fi
  sleep 2
done
python3 "$DIR/testing/check-permissions.py"
