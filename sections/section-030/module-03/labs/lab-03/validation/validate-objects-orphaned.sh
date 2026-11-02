#!/usr/bin/env bash
# Grader: the two original Object resources remain, and no TeamEnvironment
# owns them any more. That is the result of orphan deletion.
set -uo pipefail

want=$(kubectl -n starfleet get configmap lab-baseline -o jsonpath='{.data.objectUids}' 2>/dev/null)
have=$(kubectl -n outpost get objects.kubernetes.m.crossplane.io \
  -o jsonpath='{range .items[*]}{.metadata.uid}{"\n"}{end}' 2>/dev/null | sort | tr '\n' ',')
if [ -z "$want" ] || [ "$have" != "$want" ]; then
  echo "FAIL: objects-orphaned - the Object resources in outpost are not the two original ones"
  exit 1
fi
owners=$(kubectl -n outpost get objects.kubernetes.m.crossplane.io \
  -o jsonpath='{range .items[*]}{.metadata.ownerReferences[*].kind}{"\n"}{end}' 2>/dev/null | tr -d '\n')
if [ -n "$owners" ]; then
  echo "FAIL: objects-orphaned - the Object resources still have an owner reference (${owners})"
  exit 1
fi
echo "PASS: objects-orphaned - the two original Object resources remain and have no owner"
