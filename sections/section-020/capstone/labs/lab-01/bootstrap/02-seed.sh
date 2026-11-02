#!/usr/bin/env bash
# Creates the starting state of the capstone, then requests deletion of scout-settings so it
# starts in Terminating. It also records the UIDs of the objects the learner must keep, so
# the graders can tell a repaired object from a deleted and recreated one.
# Reads the two manifests next to this script's folder. Keep the paths in step with config.yaml.
set -euo pipefail

MANIFEST_DIR="$(cd "$(dirname "$0")/.." && pwd)/manifests"

kubectl apply -f "$MANIFEST_DIR/teamenvironment-crd.yaml" >/dev/null
kubectl wait --for=condition=Established --timeout=60s crd/teamenvironments.platform.starfleet.io
kubectl apply -f "$MANIFEST_DIR/lab-start.yaml" >/dev/null

prometheus_uid="$(kubectl -n outpost get prometheus outpost-metrics -o jsonpath='{.metadata.uid}')"
team_env_uid="$(kubectl -n outpost get teamenvironment scout-env -o jsonpath='{.metadata.uid}')"
kubectl -n kube-system create configmap ats019-capstone-baseline \
  --from-literal=prometheusUID="$prometheus_uid" \
  --from-literal=teamEnvironmentUID="$team_env_uid" >/dev/null

# The finalizer keeps scout-settings in the API until the cleanup worker releases it.
kubectl -n outpost delete configmap scout-settings --wait=false
