#!/usr/bin/env bash
# Check: the Service scout selects the scout pods, and that value comes from the
# Composition. The Service, the composed Object and the Composition must all
# agree, so a Service edited by hand does not pass.
set -uo pipefail
fail() { echo "FAIL: $1"; exit 1; }

SERVICE_SELECTOR="$(kubectl -n outpost get service scout -o jsonpath='{.spec.selector.app}' 2>/dev/null)"
[ "$SERVICE_SELECTOR" = "scout" ] || fail "Service scout selects app='$SERVICE_SELECTOR', expected scout"

COMPOSITION_SELECTOR="$(kubectl get composition teamenvironment -o jsonpath='{.spec.pipeline[0].input.resources[?(@.name=="service")].base.spec.forProvider.manifest.spec.selector.app}' 2>/dev/null)"
[ "$COMPOSITION_SELECTOR" = "scout" ] || fail "the Composition's service resource selects app='$COMPOSITION_SELECTOR', expected scout"

OBJECT_SELECTORS="$(kubectl -n outpost get objects.kubernetes.m.crossplane.io -o jsonpath='{range .items[*]}{.spec.forProvider.manifest.kind}={.spec.forProvider.manifest.spec.selector.app}{"\n"}{end}' 2>/dev/null)"
echo "$OBJECT_SELECTORS" | grep -qx 'Service=scout' || fail "no composed Object wraps a Service that selects app=scout"

for i in $(seq 1 24); do
  ADDRESSES="$(kubectl -n outpost get endpointslices -l kubernetes.io/service-name=scout -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]}{"\n"}{end}' 2>/dev/null | grep -c .)"
  [ "$ADDRESSES" -ge 1 ] && break
  sleep 5
done
[ "$ADDRESSES" -ge 1 ] || fail "Service scout has no endpoints"

echo "PASS: Service scout selects app=scout in the Composition, the Object and the cluster, with $ADDRESSES endpoint(s)"
