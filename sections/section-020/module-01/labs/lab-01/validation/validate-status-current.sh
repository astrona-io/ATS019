#!/usr/bin/env bash
# The status must be current: Reconciled observedGeneration equals metadata.generation,
# with the logLevel change still in the spec. Deleting and recreating the resource, or
# removing the change, does not pass (generation would stay 1).
set -u

fail() { echo "FAIL: $*"; exit 1; }
prom() { kubectl -n starfleet get prometheus starfleet -o jsonpath="$1" 2>/dev/null; }

[[ "$(prom '{.spec.logLevel}')" == "debug" ]] \
  || fail "spec.logLevel of the Prometheus resource starfleet is not debug; keep the change, do not undo it"

gen=$(prom '{.metadata.generation}')
[[ "${gen:-0}" -ge 2 ]] \
  || fail "metadata.generation is ${gen:-unset}; the original resource with the logLevel change must stay (do not delete and recreate it)"

for _ in $(seq 1 36); do
  observed=$(prom '{.status.conditions[?(@.type=="Reconciled")].observedGeneration}')
  reconciled=$(prom '{.status.conditions[?(@.type=="Reconciled")].status}')
  available=$(prom '{.status.conditions[?(@.type=="Available")].status}')
  gen=$(prom '{.metadata.generation}')
  if [[ "$observed" == "$gen" && "$reconciled" == "True" && "$available" == "True" ]]; then
    echo "PASS: Reconciled and Available are True and observedGeneration equals generation ($gen)"
    exit 0
  fi
  sleep 5
done
fail "status is not current: generation=$gen observedGeneration=${observed:-none} Reconciled=${reconciled:-none} Available=${available:-none}"
