#!/usr/bin/env bash
# Starting state in outpost: scout, the ServiceAccount `prometheus` with read access,
# and a Prometheus resource `tenant` with two faults. It names a ServiceAccount that does
# not exist, and it reads extra scrape jobs from a Secret that does not exist.
set -euo pipefail

kubectl apply -f - <<'YAML'
apiVersion: v1
kind: Namespace
metadata:
  name: outpost
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: scout
  namespace: outpost
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
  namespace: outpost
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
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: outpost
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: outpost-prometheus
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
  name: outpost-prometheus
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: outpost-prometheus
subjects:
  - kind: ServiceAccount
    name: prometheus
    namespace: outpost
---
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  name: tenant
  namespace: outpost
spec:
  replicas: 1
  serviceAccountName: prometheus-tenant
  additionalScrapeConfigs:
    name: tenant-scrape
    key: jobs.yaml
  resources:
    requests:
      memory: 100Mi
YAML

kubectl -n outpost rollout status deployment/scout --timeout=180s
