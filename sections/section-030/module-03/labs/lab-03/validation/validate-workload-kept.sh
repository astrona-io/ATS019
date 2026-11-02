#!/usr/bin/env bash
# Grader: the original scout Deployment and Service survive. Their UIDs must
# match the ones recorded at the start, so a workload that someone deleted and
# created again by hand does not pass.
set -uo pipefail

baseline() { kubectl -n starfleet get configmap lab-baseline -o jsonpath="{.data.$1}" 2>/dev/null; }

want_deployment=$(baseline deploymentUid)
want_service=$(baseline serviceUid)
have_deployment=$(kubectl -n outpost get deployment scout -o jsonpath='{.metadata.uid}' 2>/dev/null)
have_service=$(kubectl -n outpost get service scout -o jsonpath='{.metadata.uid}' 2>/dev/null)
if [ -z "$want_deployment" ] || [ -z "$want_service" ]; then
  echo "FAIL: workload-kept - the baseline ConfigMap lab-baseline in starfleet is missing; do not delete it"
  exit 1
fi
if [ "$have_deployment" != "$want_deployment" ]; then
  echo "FAIL: workload-kept - the original scout Deployment is gone or was replaced"
  exit 1
fi
if [ "$have_service" != "$want_service" ]; then
  echo "FAIL: workload-kept - the original scout Service is gone or was replaced"
  exit 1
fi
echo "PASS: workload-kept - the original scout Deployment and Service still exist"
