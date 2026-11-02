#!/usr/bin/env bash
# The operator must finish its work and the pod must run, and the status must be current.
set -u

fail() { echo "FAIL: $*"; exit 1; }
prom() { kubectl -n outpost get prometheus tenant -o jsonpath="$1" 2>/dev/null; }

for _ in $(seq 1 36); do
  gen=$(prom '{.metadata.generation}')
  observed=$(prom '{.status.conditions[?(@.type=="Reconciled")].observedGeneration}')
  reconciled=$(prom '{.status.conditions[?(@.type=="Reconciled")].status}')
  available=$(prom '{.status.conditions[?(@.type=="Available")].status}')
  if [[ "$reconciled" == "True" && "$available" == "True" && "$observed" == "$gen" ]]; then
    echo "PASS: Reconciled and Available are True and the status is current (generation $gen)"
    exit 0
  fi
  sleep 5
done
fail "Reconciled=${reconciled:-none} Available=${available:-none} generation=${gen:-none} observedGeneration=${observed:-none}"
