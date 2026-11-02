#!/usr/bin/env bash
# Check: a valid request is accepted and the API server fills in the defaults.
# Uses a server-side dry run, so nothing is stored.
set -uo pipefail
fail() { echo "FAIL: $1"; exit 1; }

REQUEST='apiVersion: platform.starfleet.io/v1alpha1
kind: ProbeEnvironment
metadata:
  name: validate-defaults
  namespace: outpost
spec:
  owner: drifter'

OUT="$(printf '%s\n' "$REQUEST" | kubectl create --dry-run=server -o jsonpath='{.spec.tier}/{.spec.instances}' -f - 2>&1)" \
  || fail "a request with only owner was refused: $OUT"
[ "$OUT" = "dev/2" ] || fail "defaults are '$OUT', expected tier dev and instances 2 (dev/2)"

FULL='apiVersion: platform.starfleet.io/v1alpha1
kind: ProbeEnvironment
metadata:
  name: validate-full
  namespace: outpost
spec:
  owner: drifter
  tier: prod
  instances: 5
  contactEmail: crew@example.com'
OUT="$(printf '%s\n' "$FULL" | kubectl create --dry-run=server -o jsonpath='{.spec.tier}/{.spec.instances}/{.spec.contactEmail}' -f - 2>&1)" \
  || fail "a request with every field set was refused: $OUT"
[ "$OUT" = "prod/5/crew@example.com" ] || fail "values were changed or pruned: '$OUT'"

echo "PASS: a valid request is accepted and defaults are tier dev, instances 2"
