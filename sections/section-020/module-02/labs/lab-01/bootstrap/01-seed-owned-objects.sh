#!/usr/bin/env bash
# Creates the TeamEnvironment CRD, the two owners and the dependents. The owner
# references need the real UIDs of the owners, so the ConfigMaps are created here
# and not from a static manifest. The UID of the two objects that must survive is
# saved in a baseline ConfigMap, so the grader can tell a kept object from a
# recreated one with the same name.
set -euo pipefail
cd "$(dirname "$0")/.."

kubectl apply -f manifests/lab-start.yaml >/dev/null
kubectl wait --for=condition=Established --timeout=120s crd/teamenvironments.platform.starfleet.io

# The API server can need a moment before it serves the new resource type.
for _ in $(seq 1 30); do
  kubectl apply -f manifests/teamenvironments.yaml >/dev/null 2>&1 && break
  sleep 2
done
kubectl -n outpost get teamenvironment scout-env probe-env >/dev/null

scout_uid=$(kubectl -n outpost get teamenvironment scout-env -o jsonpath='{.metadata.uid}')
probe_uid=$(kubectl -n outpost get teamenvironment probe-env -o jsonpath='{.metadata.uid}')

kubectl apply -f - >/dev/null <<MANIFEST
apiVersion: v1
kind: ConfigMap
metadata:
  name: scout-config
  namespace: outpost
  labels:
    team: outpost
  ownerReferences:
    - apiVersion: platform.starfleet.io/v1alpha1
      kind: TeamEnvironment
      name: scout-env
      uid: ${scout_uid}
      blockOwnerDeletion: true
data:
  mode: small
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: probe-data
  namespace: outpost
  labels:
    team: outpost
  ownerReferences:
    - apiVersion: platform.starfleet.io/v1alpha1
      kind: TeamEnvironment
      name: probe-env
      uid: ${probe_uid}
      blockOwnerDeletion: true
data:
  mode: small
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: scout-unowned
  namespace: outpost
  labels:
    team: outpost
data:
  mode: small
MANIFEST

probe_data_uid=$(kubectl -n outpost get configmap probe-data -o jsonpath='{.metadata.uid}')
unowned_uid=$(kubectl -n outpost get configmap scout-unowned -o jsonpath='{.metadata.uid}')
kubectl -n default create configmap lab-baseline \
  --from-literal=probe_data_uid="${probe_data_uid}" \
  --from-literal=scout_unowned_uid="${unowned_uid}" >/dev/null
