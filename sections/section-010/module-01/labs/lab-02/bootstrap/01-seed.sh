#!/usr/bin/env bash
# Starting state for lab-02: the namespaces, the TeamEnvironment CRD with a typed schema
# (required fields, enum, limits, defaults, pruning) but no CEL rules, no printer columns,
# no short name and no category, and one valid TeamEnvironment named alpha.
# The learner adds the rules and the columns.
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
          required:
            - spec
          properties:
            spec:
              type: object
              required:
                - team
                - size
                - contact
              properties:
                team:
                  type: string
                  minLength: 1
                  maxLength: 30
                size:
                  type: string
                  enum:
                    - small
                    - medium
                    - large
                replicas:
                  type: integer
                  minimum: 1
                  maximum: 5
                  default: 1
                contact:
                  type: string
                  pattern: '^[a-z0-9.-]+@[a-z0-9.-]+$'
                retentionDays:
                  type: integer
                  minimum: 1
                  maximum: 90
                  default: 7
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
