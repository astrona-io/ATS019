#!/usr/bin/env bash
# Wait for the intended child failure and preserve its real condition.
set -euo pipefail
cd "$(dirname "$0")/.."
kubectl apply -f manifests/composition-teamenvironment.yaml >/dev/null
kubectl apply -f manifests/teamenvironment-scout-env.yaml >/dev/null

for attempt in $(seq 1 120); do
  service_object=$(kubectl -n outpost get objects.kubernetes.m.crossplane.io \
    -o jsonpath='{range .items[?(@.spec.forProvider.manifest.kind=="Service")]}{.metadata.name}{end}')
  if [ -n "$service_object" ]; then
    reason=$(kubectl -n outpost get objects.kubernetes.m.crossplane.io "$service_object" \
      -o jsonpath='{.status.conditions[?(@.type=="Synced")].reason}')
    message=$(kubectl -n outpost get objects.kubernetes.m.crossplane.io "$service_object" \
      -o jsonpath='{.status.conditions[?(@.type=="Synced")].message}')
    synced=$(kubectl -n outpost get objects.kubernetes.m.crossplane.io "$service_object" \
      -o jsonpath='{.status.conditions[?(@.type=="Synced")].status}')
    ready=$(kubectl -n outpost get teamenvironment scout-env \
      -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
    if [ "$synced" = False ] && [ "$ready" = False ] && [ -n "$reason" ] && \
       [[ "$message" == *outpost-missing* ]]; then
      object_uid=$(kubectl -n outpost get objects.kubernetes.m.crossplane.io "$service_object" -o jsonpath='{.metadata.uid}')
      request_uid=$(kubectl -n outpost get teamenvironment scout-env -o jsonpath='{.metadata.uid}')
      kubectl -n starfleet create configmap trace-baseline \
        --from-literal=kind=Object --from-literal=name="$service_object" \
        --from-literal=uid="$object_uid" --from-literal=requestUid="$request_uid" \
        --from-literal=reason="$reason" --from-literal=message="$message" \
        --dry-run=client -o yaml | kubectl apply -f - >/dev/null
      exit 0
    fi
  fi
  sleep 5
done
echo "The intended Service Object failure did not appear" >&2
exit 1
