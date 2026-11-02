#!/usr/bin/env bash
# Grades the outcome of the operator fault. The Prometheus resource must be the original one
# (same UID), must keep its extra scrape configuration, and the operator must report
# Reconciled and Available. This rejects: deleting and recreating the resource, removing
# additionalScrapeConfigs to silence the error, and editing the operator.
set -u

NS="outpost"
fail() { echo "FAIL: $*"; exit 1; }
field() { kubectl -n "$NS" get prometheus outpost-metrics -o jsonpath="$1" 2>/dev/null; }

kubectl -n "$NS" get prometheus outpost-metrics >/dev/null 2>&1 || fail "the Prometheus resource outpost-metrics does not exist in $NS"

baseline_uid=$(kubectl -n kube-system get configmap ats019-capstone-baseline -o jsonpath='{.data.prometheusUID}' 2>/dev/null)
[[ -n "$baseline_uid" && "$(field '{.metadata.uid}')" == "$baseline_uid" ]] \
  || fail "outpost-metrics was deleted and created again; repair the original resource"

[[ "$(field '{.spec.additionalScrapeConfigs.name}')" == "extra-scrape" && "$(field '{.spec.additionalScrapeConfigs.key}')" == "jobs.yaml" ]] \
  || fail "additionalScrapeConfigs no longer points at the key jobs.yaml of the Secret extra-scrape; create the Secret instead of removing the reference"
kubectl -n "$NS" get secret extra-scrape -o jsonpath='{.data.jobs\.yaml}' >/dev/null 2>&1 \
  || fail "the Secret extra-scrape does not exist or has no key jobs.yaml"

# The operator is the controller. It must still be the installed one, running and unchanged.
operator_image=$(kubectl -n default get deployment prometheus-operator -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
[[ "$operator_image" == *"prometheus-operator:v0.94.1" ]] || fail "the Prometheus Operator deployment image is '$operator_image'; do not change the operator"
[[ "$(kubectl -n default get deployment prometheus-operator -o jsonpath='{.status.availableReplicas}' 2>/dev/null)" == "1" ]] \
  || fail "the Prometheus Operator deployment is not available"

# The operator needs time to reconcile and the pod needs time to start.
reconciled=""; available=""
for _ in $(seq 1 36); do
  reconciled=$(field '{.status.conditions[?(@.type=="Reconciled")].status}')
  available=$(field '{.status.conditions[?(@.type=="Available")].status}')
  [[ "$reconciled" == "True" && "$available" == "True" ]] && break
  sleep 5
done
[[ "$reconciled" == "True" ]] || fail "Reconciled is '$reconciled': $(field '{.status.conditions[?(@.type=="Reconciled")].message}')"
[[ "$available" == "True" ]] || fail "Available is '$available'; read the events of the StatefulSet prometheus-outpost-metrics"

# The operator, not a person, must own the StatefulSet.
owner=$(kubectl -n "$NS" get statefulset prometheus-outpost-metrics -o jsonpath='{.metadata.ownerReferences[0].kind}/{.metadata.ownerReferences[0].name}' 2>/dev/null)
[[ "$owner" == "Prometheus/outpost-metrics" ]] || fail "the StatefulSet prometheus-outpost-metrics is not owned by the Prometheus resource (owner '$owner'); do not create it by hand"

echo "PASS: outpost-metrics is the original resource, Reconciled and Available, and keeps its scrape configuration"
