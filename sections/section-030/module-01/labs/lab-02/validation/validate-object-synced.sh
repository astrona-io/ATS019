#!/usr/bin/env bash
# Grades the outcome: the Object is Synced and Ready, was not edited around the fault,
# and the Service exists with the right port and selector.
set -u

NS="outpost"
OBJ="objects.kubernetes.m.crossplane.io"
fail() { echo "FAIL: $*"; exit 1; }
field() { kubectl -n "$NS" get "$OBJ" scout -o jsonpath="$1" 2>/dev/null; }

kubectl -n "$NS" get "$OBJ" scout >/dev/null 2>&1 || fail "the Object scout does not exist in $NS"

# The Object and the ProviderConfig must keep their original meaning.
[[ "$(field '{.spec.providerConfigRef.name}')" == "in-cluster" ]] || fail "the Object no longer uses the ProviderConfig in-cluster"
[[ "$(field '{.spec.forProvider.manifest.kind}')" == "Service" ]] || fail "the Object no longer wraps a Service"
[[ "$(field '{.spec.forProvider.manifest.spec.selector.app}')" == "scout" ]] || fail "the Object manifest selector was changed"
[[ "$(field '{.spec.forProvider.manifest.spec.ports[0].port}')" == "9898" ]] || fail "the Object manifest port was changed"
source=$(kubectl -n "$NS" get providerconfigs.kubernetes.m.crossplane.io in-cluster -o jsonpath='{.spec.credentials.source}' 2>/dev/null)
[[ "$source" == "InjectedIdentity" ]] || fail "the ProviderConfig in-cluster does not use InjectedIdentity (source '$source')"

# The provider retries a failed reconcile with a growing delay, so wait for the conditions.
synced=""; ready=""
for _ in $(seq 1 30); do
  synced=$(field '{.status.conditions[?(@.type=="Synced")].status}')
  ready=$(field '{.status.conditions[?(@.type=="Ready")].status}')
  [[ "$synced" == "True" && "$ready" == "True" ]] && break
  sleep 5
done
if [[ "$synced" != "True" ]]; then
  message=$(field '{.status.conditions[?(@.type=="Synced")].message}')
  fail "the Object is not Synced (status '$synced'): $message"
fi
[[ "$ready" == "True" ]] || fail "the Object is Synced but not Ready (status '$ready')"

port=$(kubectl -n "$NS" get service scout -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)
selector=$(kubectl -n "$NS" get service scout -o jsonpath='{.spec.selector.app}' 2>/dev/null)
[[ "$port" == "9898" && "$selector" == "scout" ]] || fail "the Service scout is missing or wrong (port '$port', selector app '$selector')"

# The provider must have created the Service itself. It records that in this annotation;
# a Service created by hand before the fix leaves it empty.
created=$(field '{.metadata.annotations.crossplane\.io/external-create-succeeded}')
[[ -n "$created" ]] || fail "the provider did not create the Service; delete a hand-made Service and let the provider create it"

echo "PASS: the Object scout is Synced and Ready and the Service has the right port and selector"
