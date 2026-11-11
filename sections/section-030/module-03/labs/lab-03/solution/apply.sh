#!/usr/bin/env bash
# Pause composition before orphaning; resume deletion to let Crossplane finalize.
set -euo pipefail

kubectl -n outpost annotate teamenvironment scout-env crossplane.io/paused=true --overwrite
kubectl -n outpost wait teamenvironment/scout-env --for=jsonpath='{.status.conditions[?(@.type=="Synced")].reason}'=ReconcilePaused --timeout=180s
kubectl -n outpost delete teamenvironment scout-env --cascade=orphan --wait=false
for attempt in $(seq 1 90); do
  finalizers=$(kubectl -n outpost get teamenvironment scout-env -o jsonpath='{.metadata.finalizers[*]}')
  [ "$finalizers" = composite.apiextensions.crossplane.io ] && break
  sleep 2
done
[ "$finalizers" = composite.apiextensions.crossplane.io ] || { echo 'Orphan processing did not finish; keep reconciliation paused' >&2; exit 1; }
kubectl -n outpost annotate teamenvironment scout-env crossplane.io/paused-
kubectl -n outpost wait --for=delete teamenvironment/scout-env --timeout=180s
