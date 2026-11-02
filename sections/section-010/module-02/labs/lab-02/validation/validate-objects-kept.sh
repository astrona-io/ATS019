#!/usr/bin/env bash
# Grades that the existing objects and the schema were kept. The plausible wrong fix is to
# delete the CRD and create everything again, or to weaken the schema.
set -u

CRD="teamenvironments.platform.starfleet.io"
fail() { echo "FAIL: $*"; exit 1; }

kubectl get crd "$CRD" >/dev/null 2>&1 || fail "the CRD $CRD does not exist"

for name in alpha beta; do
  want=$(kubectl -n starfleet get configmap seed-record -o jsonpath="{.data.$name-uid}" 2>/dev/null)
  [[ -n "$want" ]] || fail "the seed record for $name is missing; the lab cannot be graded"
  got=$(kubectl -n outpost get teamenvironment.v1.platform.starfleet.io "$name" -o jsonpath='{.metadata.uid}' 2>/dev/null)
  [[ "$got" == "$want" ]] || fail "$name is not the original object (uid '$got', expected '$want'); do not delete and create objects again"
done

versions=$(kubectl get crd "$CRD" -o jsonpath='{range .spec.versions[*]}{.name}{" served="}{.served}{" storage="}{.storage}{"\n"}{end}')
[[ "$versions" == "v1 served=true storage=true" ]] || fail "the CRD must still have only v1, served and stored; found: $(echo "$versions" | tr '\n' ';')"

# The schema must still reject bad input.
for bad in "size: huge" "size: small
  replicas: 9" "size: small
  replcas: 2"; do
  if kubectl apply --dry-run=server -f - >/dev/null 2>&1 <<YAML
apiVersion: platform.starfleet.io/v1
kind: TeamEnvironment
metadata:
  name: probe-bad
  namespace: outpost
spec:
  team: outpost
  $bad
YAML
  then
    fail "the API server accepted invalid input ($(echo "$bad" | tr '\n' ' ')); do not weaken the schema"
  fi
done

echo "PASS: alpha and beta are the original objects and the schema still rejects bad input"
