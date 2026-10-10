#!/usr/bin/env bash
# Creates the namespaces, the TeamEnvironment CRD with a weak schema, and three
# objects that schema accepts: `alpha` is valid, `beta` misspells `replicas`,
# `gamma` asks for 50 replicas and an unknown size.
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
---
apiVersion: platform.starfleet.io/v1alpha1
kind: TeamEnvironment
metadata:
  name: beta
  namespace: outpost
spec:
  team: outpost
  size: medium
  replcas: 3
  contact: lead@outpost.starfleet.io
---
apiVersion: platform.starfleet.io/v1alpha1
kind: TeamEnvironment
metadata:
  name: gamma
  namespace: outpost
spec:
  team: outpost
  size: huge
  replicas: 50
  contact: nobody
YAML
