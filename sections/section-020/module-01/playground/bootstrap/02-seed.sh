#!/usr/bin/env bash
# The starting state in `starfleet`: scout and shuttle, a ServiceMonitor for
# scout, a ServiceAccount with the read access Prometheus needs, one working
# Prometheus resource and one that names a missing ServiceAccount.
set -euo pipefail

kubectl apply -f - <<'YAML'
apiVersion: v1
kind: Namespace
metadata:
  name: starfleet
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: scout
  namespace: starfleet
  labels:
    app: scout
spec:
  replicas: 1
  selector:
    matchLabels:
      app: scout
  template:
    metadata:
      labels:
        app: scout
    spec:
      containers:
        - name: scout
          image: ghcr.io/stefanprodan/podinfo:6.15.0
          ports:
            - name: http
              containerPort: 9898
          resources:
            requests:
              cpu: 10m
              memory: 32Mi
---
apiVersion: v1
kind: Service
metadata:
  name: scout
  namespace: starfleet
  labels:
    app: scout
spec:
  selector:
    app: scout
  ports:
    - name: http
      port: 9898
      targetPort: http
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shuttle
  namespace: starfleet
spec:
  replicas: 1
  selector:
    matchLabels:
      app: shuttle
  template:
    metadata:
      labels:
        app: shuttle
    spec:
      containers:
        - name: shuttle
          image: curlimages/curl:8.22.0
          command: ["sh", "-c", "while true; do sleep 30; done"]
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: scout
  namespace: starfleet
  labels:
    team: starfleet
spec:
  selector:
    matchLabels:
      app: scout
  endpoints:
    - port: http
      path: /metrics
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
  serviceMonitorSelector:
    matchLabels:
      team: starfleet
  resources:
    requests:
      memory: 100Mi
---
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  name: broken
  namespace: starfleet
spec:
  replicas: 1
  serviceAccountName: prometheus-reader
  serviceMonitorSelector:
    matchLabels:
      team: starfleet
  resources:
    requests:
      memory: 100Mi
YAML

kubectl -n starfleet rollout status deployment/scout --timeout=120s
kubectl -n starfleet rollout status deployment/shuttle --timeout=120s
kubectl -n starfleet wait --for=condition=Available --timeout=240s prometheus/starfleet
