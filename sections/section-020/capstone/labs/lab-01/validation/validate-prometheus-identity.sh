#!/usr/bin/env bash
# Grades the identity the Prometheus pods use. The resource must name the ServiceAccount the
# platform team prepared, and that ServiceAccount must read targets and nothing more. This
# rejects: a new empty ServiceAccount named prometheus-reader (pod starts, no access), the
# default ServiceAccount, and cluster-admin for the Prometheus ServiceAccount.
set -u

NS="outpost"
fail() { echo "FAIL: $*"; exit 1; }

sa=$(kubectl -n "$NS" get prometheus outpost-metrics -o jsonpath='{.spec.serviceAccountName}' 2>/dev/null)
[[ "$sa" == "prometheus" ]] || fail "spec.serviceAccountName is '$sa'; use the ServiceAccount prometheus that already exists in $NS"

pod_sa=$(kubectl -n "$NS" get pod prometheus-outpost-metrics-0 -o jsonpath='{.spec.serviceAccountName}' 2>/dev/null)
[[ "$pod_sa" == "prometheus" ]] || fail "the pod prometheus-outpost-metrics-0 runs as '$pod_sa', not prometheus"

as="system:serviceaccount:$NS:prometheus"
can() { kubectl auth can-i "$@" --as="$as" 2>/dev/null; }
for resource in pods endpoints services endpointslices.discovery.k8s.io; do
  [[ "$(can list "$resource" -n "$NS")" == "yes" ]] || fail "the ServiceAccount prometheus cannot list $resource in $NS"
done
[[ "$(can create deployments.apps -n "$NS")" == "no" ]] || fail "the ServiceAccount prometheus can create Deployments; it must only read targets"
[[ "$(can delete configmaps -n "$NS")" == "no" ]] || fail "the ServiceAccount prometheus can delete ConfigMaps; do not widen its access"
[[ "$(can '*' '*' --all-namespaces)" == "no" ]] || fail "the ServiceAccount prometheus has wildcard access; do not give it cluster-admin"

echo "PASS: the Prometheus pods run as prometheus, which reads targets and nothing more"
