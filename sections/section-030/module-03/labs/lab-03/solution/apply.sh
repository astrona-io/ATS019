#!/usr/bin/env bash
# Pause composition before orphaning; resume deletion to let Crossplane finalize.
set -euo pipefail

kubectl -n outpost annotate teamenvironment scout-env crossplane.io/paused=true --overwrite
kubectl -n outpost wait teamenvironment/scout-env --for=jsonpath='{.status.conditions[?(@.type=="Synced")].reason}'=ReconcilePaused --timeout=180s
kubectl -n outpost delete teamenvironment scout-env --cascade=orphan --wait=false
kubectl -n outpost annotate teamenvironment scout-env crossplane.io/paused-
kubectl -n outpost wait --for=delete teamenvironment/scout-env --timeout=180s
