#!/usr/bin/env bash
# Starting state for lab-01: the namespaces, the TeamEnvironment CRD with a weak schema
# (spec keeps any field, nothing is required, no limits, no defaults) and one valid
# TeamEnvironment named alpha. The learner replaces the schema.
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
              x-kubernetes-preserve-unknown-fields: true
YAML

kubectl wait --for=condition=Established --timeout=60s \
  crd/teamenvironments.platform.starfleet.io

kubectl apply -f - <<'YAML'
apiVersion: platform.starfleet.io/v1alpha1
kind: TeamEnvironment
metadata:
  name: alpha
  namespace: outpost
spec:
  team: outpost
  size: small
  replicas: 2
  contact: lead@outpost.starfleet.io
YAML
