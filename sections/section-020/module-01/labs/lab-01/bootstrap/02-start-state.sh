#!/usr/bin/env bash
# Starting state: a working Prometheus resource in starfleet, then the operator is
# stopped and the spec is changed, so the status is older than the spec.
set -euo pipefail

kubectl apply -f - <<'YAML'
apiVersion: v1
kind: Namespace
metadata:
  name: starfleet
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: starfleet
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: starfleet-prometheus
rules:
  - apiGroups: [""]
    resources: ["services", "endpoints", "pods"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["discovery.k8s.io"]
    resources: ["endpointslices"]
    verbs: ["get", "list", "watch"]
  - nonResourceURLs: ["/metrics"]
    verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: starfleet-prometheus
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: starfleet-prometheus
subjects:
  - kind: ServiceAccount
    name: prometheus
    namespace: starfleet
---
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  name: starfleet
  namespace: starfleet
spec:
  replicas: 1
  serviceAccountName: prometheus
  resources:
    requests:
      memory: 100Mi
YAML

kubectl -n starfleet wait --for=condition=Available --timeout=300s prometheus/starfleet

# Stop the controller, then change the spec while it is down.
kubectl -n default scale deployment prometheus-operator --replicas=0
kubectl -n default wait --for=delete pod -l app.kubernetes.io/name=prometheus-operator --timeout=120s
kubectl -n starfleet patch prometheus starfleet --type merge -p '{"spec":{"logLevel":"debug"}}'
