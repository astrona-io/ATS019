#!/usr/bin/env bash
# The starting state: a Prometheus resource `starfleet` that owns its
# StatefulSet, Service and Secrets; a ConfigMap `scout-settings` that carries
# the finalizer `platform.starfleet.io/cleanup`, which no controller removes;
# and the TeamEnvironment CRD for ownerReference experiments.
set -euo pipefail

kubectl apply -f - <<'YAML'
apiVersion: v1
kind: Namespace
metadata:
  name: starfleet
---
apiVersion: v1
kind: Namespace
metadata:
  name: outpost
---
apiVersion: v1
kind: ServiceAccount
metadata:
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
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: scout-settings
  namespace: starfleet
  finalizers:
    - platform.starfleet.io/cleanup
data:
  PODINFO_UI_MESSAGE: hello from starfleet
---
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: teamenvironments.platform.starfleet.io
spec:
  group: platform.starfleet.io
  scope: Namespaced
  names:
    kind: TeamEnvironment
    plural: teamenvironments
    singular: teamenvironment
    shortNames:
      - teamenv
  versions:
    - name: v1alpha1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              required:
                - team
                - size
              properties:
                team:
                  type: string
                size:
                  type: string
                  enum:
                    - small
                    - medium
                    - large
YAML

kubectl -n starfleet wait --for=condition=Available --timeout=240s prometheus/starfleet
