#!/usr/bin/env bash
# Record the real failure before repairing the Composition.
set -euo pipefail
object_name=$(kubectl -n starfleet get configmap trace-baseline -o jsonpath='{.data.name}')
reason=$(kubectl -n outpost get objects.kubernetes.m.crossplane.io "$object_name" -o jsonpath='{.status.conditions[?(@.type=="Synced")].reason}')
message=$(kubectl -n outpost get objects.kubernetes.m.crossplane.io "$object_name" -o jsonpath='{.status.conditions[?(@.type=="Synced")].message}')
kubectl -n outpost create configmap trace-report \
  --from-literal=kind=Object --from-literal=name="$object_name" \
  --from-literal=reason="$reason" --from-literal=message="$message" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl patch composition teamenvironment --type=json \
  -p='[{"op":"replace","path":"/spec/pipeline/0/input/resources/1/base/spec/providerConfigRef/name","value":"in-cluster"}]'
kubectl -n outpost wait teamenvironment/scout-env --for=condition=Ready --timeout=600s
kubectl -n outpost wait teamenvironment/scout-env --for=condition=Synced --timeout=120s
