#!/usr/bin/env bash
# Starting state for the capstone: the namespaces, a weak Database CRD that serves only
# v1alpha1 (preserve-unknown-fields, no required fields, no subresources, no printer
# columns), and two valid objects stored as v1alpha1. The UIDs of the two objects are
# saved in a ConfigMap so the grader can tell whether the learner deleted and recreated them.
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
  name: databases.platform.starfleet.io
spec:
  group: platform.starfleet.io
  scope: Namespaced
  names:
    kind: Database
    plural: databases
    singular: database
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

kubectl wait --for=condition=Established --timeout=60s crd/databases.platform.starfleet.io

kubectl apply -f - <<'YAML'
apiVersion: platform.starfleet.io/v1alpha1
kind: Database
metadata:
  name: orders-db
  namespace: outpost
spec:
  team: orders
  engine: postgres
  storageGB: 50
  replicas: 1
---
apiVersion: platform.starfleet.io/v1alpha1
kind: Database
metadata:
  name: billing-db
  namespace: outpost
spec:
  team: billing
  engine: mysql
  storageGB: 10
  replicas: 1
YAML

orders_uid=$(kubectl -n outpost get databases.v1alpha1.platform.starfleet.io orders-db -o jsonpath='{.metadata.uid}')
billing_uid=$(kubectl -n outpost get databases.v1alpha1.platform.starfleet.io billing-db -o jsonpath='{.metadata.uid}')

kubectl -n starfleet create configmap database-baseline \
  --from-literal=orders-db="$orders_uid" \
  --from-literal=billing-db="$billing_uid"
