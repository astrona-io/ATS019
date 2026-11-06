#!/usr/bin/env bash
# Check the actual repaired Composition, both live children and original request.
set -euo pipefail
fail() { echo "FAIL: request-ready - $*"; exit 1; }
request() { kubectl -n outpost get teamenvironment scout-env -o "jsonpath=$1"; }
[ "$(request '{.metadata.uid}')" = "$(kubectl -n starfleet get configmap trace-baseline -o jsonpath='{.data.requestUid}')" ] || fail "keep the original request"
[ "$(request '{.spec.crossplane.compositionRef.name}')" = teamenvironment ] || fail "keep the selected Composition"
[ "$(request '{.spec.team}')" = outpost ] || fail "keep spec.team"
for condition in Synced Ready; do
  [ "$(request "{.status.conditions[?(@.type==\"$condition\")].status}")" = True ] || fail "request $condition must be True"
done
provider_name=$(kubectl get composition teamenvironment -o jsonpath='{.spec.pipeline[0].input.resources[?(@.name=="service")].base.spec.providerConfigRef.name}')
[ "$provider_name" = in-cluster ] || fail "fix the service ProviderConfig reference in the Composition"
provider_kind=$(kubectl get composition teamenvironment -o jsonpath='{.spec.pipeline[0].input.resources[?(@.name=="service")].base.spec.providerConfigRef.kind}')
[ "$provider_kind" = ClusterProviderConfig ] || fail "keep the ClusterProviderConfig reference kind"
if kubectl get clusterproviderconfigs.kubernetes.m.crossplane.io outpost-missing >/dev/null 2>&1; then
  fail "repair the reference rather than creating outpost-missing"
fi
children=$(request '{range .spec.crossplane.resourceRefs[*]}{.name}{"\n"}{end}')
[ "$(printf '%s\n' "$children" | wc -l | tr -d ' ')" = 2 ] || fail "keep both composed Objects"
for child in $children; do
  for condition in Synced Ready; do
    status=$(kubectl -n outpost get objects.kubernetes.m.crossplane.io "$child" -o "jsonpath={.status.conditions[?(@.type==\"$condition\")].status}")
    [ "$status" = True ] || fail "$child $condition must be True"
  done
done
# The baseline stores the failing child's uid, not its name; find it by uid.
object_uid=$(kubectl -n starfleet get configmap trace-baseline -o jsonpath='{.data.uid}')
object_name=$(kubectl -n outpost get objects.kubernetes.m.crossplane.io -o jsonpath="{.items[?(@.metadata.uid==\"$object_uid\")].metadata.name}")
[ -n "$object_name" ] || fail "keep the original failing child"
[ "$(kubectl -n outpost get objects.kubernetes.m.crossplane.io "$object_name" -o jsonpath='{.spec.providerConfigRef.name}')" = in-cluster ] || fail "live child must use in-cluster"
[ "$(kubectl -n outpost get objects.kubernetes.m.crossplane.io "$object_name" -o jsonpath='{.spec.providerConfigRef.kind}')" = ClusterProviderConfig ] || fail "live child must use ClusterProviderConfig"
kubectl -n outpost get service scout >/dev/null || fail "provider must create the Service"
echo "PASS: request-ready - original request and children are Synced and Ready"
