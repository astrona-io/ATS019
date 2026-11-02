#!/usr/bin/env bash
# Grader: the tenant request is correct and works. scout-env keeps the values from the
# task, is Synced and Ready, shows the available replicas in its status, lists exactly two
# composed Object resources that are Ready, and the workload they made has the right image,
# pod label and Service.
set -uo pipefail
fail() { echo "FAIL: request-ready - $1"; exit 1; }
xr() { kubectl -n outpost get teamenvironment scout-env -o jsonpath="$1" 2>/dev/null; }

[ -n "$(xr '{.metadata.name}')" ] || fail "no TeamEnvironment named scout-env in the namespace outpost"
team=$(xr '{.spec.team}'); size=$(xr '{.spec.size}'); replicas=$(xr '{.spec.replicas}')
if [ "$team" != "outpost" ] || [ "$size" != "medium" ] || [ "$replicas" != "2" ]; then
  fail "the request has team=${team} size=${size} replicas=${replicas}, expected outpost, medium, 2"
fi

synced=""; ready=""; available=""
for _ in $(seq 1 60); do
  synced=$(xr '{.status.conditions[?(@.type=="Synced")].status}')
  ready=$(xr '{.status.conditions[?(@.type=="Ready")].status}')
  available=$(xr '{.status.availableReplicas}')
  [ "$synced" = "True" ] && [ "$ready" = "True" ] && [ "${available:-0}" -ge 1 ] 2>/dev/null && break
  sleep 5
done
[ "$synced" = "True" ] || fail "scout-env is not Synced (status '${synced:-missing}'); trace it with crossplane resource trace"
[ "$ready" = "True" ] || fail "scout-env is Synced but not Ready (status '${ready:-missing}'); trace it with crossplane resource trace"
# provider-kubernetes refreshes the Object status on a poll interval, so the value can lag
# behind the Deployment for a while. Any positive number proves the Composition writes it back.
[ "${available:-0}" -ge 1 ] 2>/dev/null || fail "status.availableReplicas is '${available:-empty}', expected a number written back by the Composition"

kinds=$(xr '{range .spec.crossplane.resourceRefs[*]}{.kind}{"\n"}{end}' | sort | uniq -c | tr -s ' ' | tr '\n' ';')
[ "$kinds" = " 2 Object;" ] || [ "$kinds" = "2 Object;" ] || fail "the request lists the composed resources '${kinds}', expected two Object resources"
for name in $(xr '{range .spec.crossplane.resourceRefs[*]}{.name}{"\n"}{end}'); do
  object_ready=$(kubectl -n outpost get objects.kubernetes.m.crossplane.io "$name" \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
  [ "$object_ready" = "True" ] || fail "the composed Object ${name} is not Ready (status '${object_ready:-missing}')"
done

image=$(kubectl -n outpost get deployment scout -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
label=$(kubectl -n outpost get deployment scout -o jsonpath='{.spec.template.metadata.labels.team}' 2>/dev/null)
[ "$image" = "ghcr.io/stefanprodan/podinfo:6.15.0" ] || fail "the Deployment scout uses the image '${image:-none}', expected ghcr.io/stefanprodan/podinfo:6.15.0"
[ "$label" = "outpost" ] || fail "the pods of scout carry team='${label:-none}', expected the value of spec.team (outpost)"
port=$(kubectl -n outpost get service scout -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)
selector=$(kubectl -n outpost get service scout -o jsonpath='{.spec.selector.app}' 2>/dev/null)
[ "$port" = "9898" ] && [ "$selector" = "scout" ] || fail "the Service scout has port '${port:-none}' and selector app='${selector:-none}', expected 9898 and scout"

echo "PASS: request-ready - scout-env is Synced and Ready, reports available replicas and owns two Ready Objects"
