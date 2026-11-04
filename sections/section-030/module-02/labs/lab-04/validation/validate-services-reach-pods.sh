#!/usr/bin/env bash
# Check ownership, selectors, ready EndpointSlice targets and real HTTP requests.
source "$(dirname "$0")/common.sh"
for name in outpost-scout outpost-probe; do
  check_owned_service "$name"
  require_equal "$(field -n outpost get service "$name" -o 'jsonpath={.spec.type}')" ClusterIP "$name must be ClusterIP"
  ADDRESS="$(field -n outpost get service "$name" -o 'jsonpath={.spec.clusterIP}')"
  [ -n "$ADDRESS" ] && [ "$ADDRESS" != None ] || fail "$name must have an allocated clusterIP"
  require_equal "$(field -n outpost get service "$name" -o 'jsonpath={.spec.selector.app}')" "$name" "$name Service selects the wrong Pods"
  require_equal "$(field -n outpost get statefulset "$name" -o 'jsonpath={.spec.template.metadata.labels.app}')" "$name" "$name StatefulSet has the wrong Pod label"
  require_equal "$(field -n outpost get service "$name" -o 'jsonpath={.spec.ports[0].port}')" 9898 "$name Service port must be 9898"
  require_equal "$(field -n outpost get service "$name" -o 'jsonpath={.spec.ports[0].targetPort}')" 9898 "$name targetPort must be 9898"
  TARGETS="$(field -n outpost get endpointslices -l "kubernetes.io/service-name=$name" -o 'jsonpath={range .items[*].endpoints[?(@.conditions.ready==true)]}{.targetRef.name}{"\n"}{end}')"
  echo "$TARGETS" | grep -qx "$name-0" || fail "$name has no ready EndpointSlice target for $name-0"
  require_equal "$(field -n outpost get pod "$name-0" -o 'jsonpath={.metadata.ownerReferences[?(@.controller==true)].uid}')" "$(field -n outpost get statefulset "$name" -o 'jsonpath={.metadata.uid}')" "$name endpoint Pod does not belong to its StatefulSet"
  CODE="$(kubectl -n outpost exec outpost-scout-0 -- curl -sS --max-time 5 -o /dev/null -w '%{http_code}' "http://$name:9898")" || fail "$name request failed"
  require_equal "$CODE" 200 "$name must answer HTTP 200"
done
echo 'PASS: services-reach-pods'
