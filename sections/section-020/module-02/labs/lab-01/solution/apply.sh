#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`. Keep in step with solution.md.
set -euo pipefail
cd "$(dirname "$0")"

kubectl apply -f solution.yaml
v2_uid=$(kubectl -n outpost get teamenvironment probe-env-v2 -o jsonpath='{.metadata.uid}')

# A JSON merge patch replaces the whole ownerReferences list.
kubectl -n outpost patch configmap probe-data --type=merge -p "{\"metadata\":{\"ownerReferences\":[{\"apiVersion\":\"platform.starfleet.io/v1alpha1\",\"kind\":\"TeamEnvironment\",\"name\":\"probe-env-v2\",\"uid\":\"${v2_uid}\",\"blockOwnerDeletion\":true}]}}"

kubectl -n outpost delete teamenvironment probe-env --cascade=background --timeout=60s
kubectl -n outpost delete teamenvironment scout-env --cascade=foreground --timeout=60s
kubectl -n outpost wait --for=delete configmap/scout-config --timeout=60s
