#!/usr/bin/env bash
# Grader: the Deployment runs the replicas the tenant asked for. Crossplane and the provider reset a hand-edited
# Deployment, so only a working Composition keeps this true.
set -uo pipefail

replicas=$(kubectl -n outpost get deployment scout -o jsonpath='{.spec.replicas}' 2>/dev/null)
available=$(kubectl -n outpost get deployment scout -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ -z "$replicas" ]; then
  echo "FAIL: workload-follows-request - no Deployment named scout in the namespace outpost"
  exit 1
fi
if [ "$replicas" != "2" ] || [ "$available" != "2" ]; then
  echo "FAIL: workload-follows-request - expected 2, got Deployment replicas=${replicas} available=${available:-0}"
  exit 1
fi
if ! kubectl -n outpost get service scout >/dev/null 2>&1; then
  echo "FAIL: workload-follows-request - no Service named scout in the namespace outpost"
  exit 1
fi
echo "PASS: workload-follows-request - the scout Deployment runs 2 replicas"
