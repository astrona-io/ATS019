#!/usr/bin/env bash
# Creates the starting state for the lab: a ready TeamEnvironment named
# scout-env, its composed resources and a working `scout` workload. Then it
# records the UIDs of the objects so the grader can tell the original workload
# from a copy that someone created by hand.
set -euo pipefail
cd "$(dirname "$0")/.."

kubectl apply -f manifests/shuttle.yaml >/dev/null
kubectl apply -f manifests/composition-teamenvironment.yaml >/dev/null
kubectl -n outpost rollout status deployment/shuttle --timeout=180s
kubectl apply -f manifests/teamenvironment-scout-env.yaml >/dev/null
kubectl -n outpost wait teamenvironment/scout-env --for=condition=Ready --timeout=600s
kubectl -n outpost rollout status deployment/scout --timeout=300s

status=000
for i in $(seq 1 30); do
  status=$(kubectl -n outpost exec deploy/shuttle -- \
    curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://scout:9898 || true)
  [ "$status" = "200" ] && break
  sleep 3
done
[ "$status" = "200" ] || { echo "scout did not answer 200" >&2; exit 1; }

deployment_uid=$(kubectl -n outpost get deployment scout -o jsonpath='{.metadata.uid}')
service_uid=$(kubectl -n outpost get service scout -o jsonpath='{.metadata.uid}')
object_uids=$(kubectl -n outpost get objects.kubernetes.m.crossplane.io \
  -o jsonpath='{range .items[*]}{.metadata.uid}{"\n"}{end}' | sort | tr '\n' ',')
kubectl -n starfleet create configmap lab-baseline \
  --from-literal=deploymentUid="$deployment_uid" \
  --from-literal=serviceUid="$service_uid" \
  --from-literal=objectUids="$object_uids" \
  --dry-run=client -o yaml | kubectl apply -f - >/dev/null
