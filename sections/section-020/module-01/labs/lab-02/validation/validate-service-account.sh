#!/usr/bin/env bash
# The pod must run under a ServiceAccount that can read targets. A new ServiceAccount
# with the missing name but no RBAC passes the status but fails here, and so does
# cluster-admin. The pod must come from the StatefulSet that the operator owns.
set -u

fail() { echo "FAIL: $*"; exit 1; }
can() { kubectl auth can-i "$@" --as="system:serviceaccount:outpost:$SA" 2>/dev/null; }

SA=$(kubectl -n outpost get prometheus tenant -o jsonpath='{.spec.serviceAccountName}' 2>/dev/null)
[[ -n "$SA" ]] || fail "the Prometheus resource tenant has no serviceAccountName"
kubectl -n outpost get serviceaccount "$SA" >/dev/null 2>&1 || fail "the ServiceAccount $SA does not exist in outpost"

for resource in pods services endpoints; do
  for verb in get list watch; do
    [[ "$(can "$verb" "$resource" -n outpost)" == "yes" ]] \
      || fail "the ServiceAccount $SA cannot $verb $resource in outpost, so Prometheus could not find targets"
  done
done
[[ "$(can create deployments.apps -n outpost)" == "no" ]] \
  || fail "the ServiceAccount $SA can create Deployments; do not give Prometheus more than read access"
[[ "$(can '*' '*' -n outpost)" == "no" ]] \
  || fail "the ServiceAccount $SA can do everything in outpost; do not use cluster-admin"

for _ in $(seq 1 36); do
  pod_sa=$(kubectl -n outpost get pod prometheus-tenant-0 -o jsonpath='{.spec.serviceAccountName}' 2>/dev/null)
  ready=$(kubectl -n outpost get pod prometheus-tenant-0 -o jsonpath='{.status.containerStatuses[?(@.name=="prometheus")].ready}' 2>/dev/null)
  [[ "$pod_sa" == "$SA" && "$ready" == "true" ]] && break
  sleep 5
done
[[ "$pod_sa" == "$SA" ]] || fail "the pod prometheus-tenant-0 does not run as $SA (found: ${pod_sa:-no pod})"
[[ "$ready" == "true" ]] || fail "the prometheus container in prometheus-tenant-0 is not ready"

owner=$(kubectl -n outpost get pod prometheus-tenant-0 -o jsonpath='{.metadata.ownerReferences[0].kind}' 2>/dev/null)
[[ "$owner" == "StatefulSet" ]] || fail "the pod prometheus-tenant-0 is not owned by a StatefulSet; do not create pods by hand"

echo "PASS: Prometheus runs as $SA, which can read targets and nothing wider"
