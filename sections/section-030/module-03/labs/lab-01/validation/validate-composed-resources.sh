#!/usr/bin/env bash
# Grader: Crossplane composed two Object resources for the request and both are Ready.
# Objects that Crossplane created are listed in spec.crossplane.resourceRefs; a
# workload created by hand has no Object behind it.
set -uo pipefail

refs=$(kubectl -n outpost get teamenvironment scout-env \
  -o jsonpath='{range .spec.crossplane.resourceRefs[*]}{.kind}/{.name}{"\n"}{end}' 2>/dev/null)
count=$(printf '%s\n' "$refs" | grep -c '^Object/')
if [ "$count" != "2" ]; then
  echo "FAIL: composed-resources - expected 2 Object references on scout-env, found ${count}"
  exit 1
fi
for ref in $refs; do
  name=${ref#Object/}
  ready=$(kubectl -n outpost get objects.kubernetes.m.crossplane.io "$name" \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
  if [ "$ready" != "True" ]; then
    echo "FAIL: composed-resources - Object ${name} is not Ready (Ready=${ready:-missing})"
    exit 1
  fi
done
echo "PASS: composed-resources - both composed Object resources are Ready"
