#!/usr/bin/env bash
# Lab start state: the TeamEnvironment CRD with a full schema in one version
# (v1, served and stored, no subresources) and two objects stored as v1. The
# graders also get a record of the object uids from a ConfigMap.
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
    shortNames:
      - teamenv
  versions:
    - name: v1
      served: true
      storage: true
      additionalPrinterColumns:
        - name: Size
          type: string
          jsonPath: .spec.size
        - name: Replicas
          type: integer
          jsonPath: .spec.replicas
        - name: Ready
          type: integer
          jsonPath: .status.readyReplicas
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
                replicas:
                  type: integer
                  minimum: 0
                  maximum: 5
                  default: 1
            status:
              type: object
              properties:
                readyReplicas:
                  type: integer
                phase:
                  type: string
YAML

kubectl wait --for=condition=Established --timeout=60s \
  crd/teamenvironments.platform.starfleet.io

kubectl apply -f - <<'YAML'
apiVersion: platform.starfleet.io/v1
kind: TeamEnvironment
metadata:
  name: alpha
  namespace: outpost
spec:
  team: outpost
  size: small
  replicas: 2
---
apiVersion: platform.starfleet.io/v1
kind: TeamEnvironment
metadata:
  name: beta
  namespace: outpost
spec:
  team: outpost
  size: medium
  replicas: 3
YAML

# Record the uid of each seeded object. The graders compare these uids to prove that
# the objects were kept and not deleted and created again.
alpha_uid=$(kubectl -n outpost get teamenvironment alpha -o jsonpath='{.metadata.uid}')
beta_uid=$(kubectl -n outpost get teamenvironment beta -o jsonpath='{.metadata.uid}')
kubectl -n starfleet create configmap seed-record \
  --from-literal=alpha-uid="$alpha_uid" \
  --from-literal=beta-uid="$beta_uid"
