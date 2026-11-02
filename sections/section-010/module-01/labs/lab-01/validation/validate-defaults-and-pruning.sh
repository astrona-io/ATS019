#!/usr/bin/env bash
# Grades behaviour: a valid object is accepted, gets the defaults, keeps the limits of the
# range, and a misspelled field is refused (strict) or pruned (not strict), never stored.
# The schema must not use x-kubernetes-preserve-unknown-fields to get there.
set -u

CRD="teamenvironments.platform.starfleet.io"
fail() { echo "FAIL: $*"; exit 1; }

manifest() {
  printf '{"apiVersion":"platform.starfleet.io/v1alpha1","kind":"TeamEnvironment","metadata":{"name":"grader-check","namespace":"outpost"},"spec":%s}' "$1"
}

# Wait for the new schema: a valid object without replicas must come back with replicas 1.
replicas=""
for _ in $(seq 1 20); do
  replicas=$(manifest '{"team":"outpost","size":"medium","contact":"lead@outpost.starfleet.io"}' \
    | kubectl create --dry-run=server -f - -o jsonpath='{.spec.replicas}' 2>/dev/null)
  [[ "$replicas" == "1" ]] && break
  sleep 3
done
[[ "$replicas" == "1" ]] || fail "a TeamEnvironment without replicas does not get replicas 1 (got '$replicas')"

retention=$(manifest '{"team":"outpost","size":"medium","contact":"lead@outpost.starfleet.io"}' \
  | kubectl create --dry-run=server -f - -o jsonpath='{.spec.retentionDays}' 2>/dev/null)
[[ "$retention" == "7" ]] || fail "a TeamEnvironment without retentionDays does not get retentionDays 7 (got '$retention')"

# A value the user sets is kept, and the edges of the allowed range are accepted.
for spec in \
  '{"team":"outpost","size":"large","replicas":5,"retentionDays":90,"contact":"lead@outpost.starfleet.io"}' \
  '{"team":"outpost","size":"small","replicas":1,"retentionDays":1,"contact":"lead@outpost.starfleet.io"}'; do
  manifest "$spec" | kubectl create --dry-run=server -f - -o name >/dev/null 2>&1 \
    || fail "the API server refused a valid object at the edge of the range: $spec"
done
kept=$(manifest '{"team":"outpost","size":"large","replicas":4,"contact":"lead@outpost.starfleet.io"}' \
  | kubectl create --dry-run=server -f - -o jsonpath='{.spec.replicas}' 2>/dev/null)
[[ "$kept" == "4" ]] || fail "replicas 4 was changed to '$kept'"

# Unknown fields: kubectl uses strict validation and must be refused.
output=$(manifest '{"team":"outpost","size":"small","replcas":2,"contact":"lead@outpost.starfleet.io"}' \
  | kubectl create --dry-run=server -f - -o name 2>&1) \
  && fail "the API server accepted the misspelled field replcas"
[[ "$output" == *"replcas"* ]] || fail "the misspelled field was refused, but the error does not name replcas: $output"

# Without strict validation the field must be pruned, not stored.
pruned=$(manifest '{"team":"outpost","size":"small","replcas":2,"contact":"lead@outpost.starfleet.io"}' \
  | kubectl create --dry-run=server --validate=false -f - -o jsonpath='{.spec.replcas}' 2>/dev/null)
[[ -z "$pruned" ]] || fail "the field replcas is kept (value '$pruned'); the schema does not prune unknown fields"

# The plausible wrong fix: keep unknown fields.
if kubectl get crd "$CRD" -o jsonpath='{.spec.versions}' | grep -q 'x-kubernetes-preserve-unknown-fields'; then
  fail "the schema still uses x-kubernetes-preserve-unknown-fields"
fi

echo "PASS: the API server defaults replicas and retentionDays, accepts the edges of the range and prunes unknown fields"
