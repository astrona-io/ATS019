#!/usr/bin/env bash
# Grades behaviour: the cross-field rule (a small environment runs at most 2 replicas) on
# create and on update, and the transition rule (team cannot change). Uses server-side dry
# runs, so nothing is stored. A rule that comes from the schema limits, not from CEL, fails.
set -u

fail() { echo "FAIL: $*"; exit 1; }

dry_run_create() {
  printf '{"apiVersion":"platform.starfleet.io/v1alpha1","kind":"TeamEnvironment","metadata":{"name":"grader-check","namespace":"outpost"},"spec":%s}' "$1" \
    | kubectl create --dry-run=server -f - -o name 2>&1
}
dry_run_patch() {
  kubectl -n outpost patch teamenvironment alpha --type merge -p "$1" --dry-run=server -o name 2>&1
}

# The CRD update takes a moment to reach the API server: wait until small with 3 replicas is refused.
for _ in $(seq 1 20); do
  dry_run_create '{"team":"outpost","size":"small","replicas":3,"contact":"lead@outpost.starfleet.io"}' >/dev/null && sleep 3 || break
done

# Create: small with 3 replicas is refused by a rule, not by a schema limit.
output=$(dry_run_create '{"team":"outpost","size":"small","replicas":3,"contact":"lead@outpost.starfleet.io"}') \
  && fail "the API server accepted a small environment with 3 replicas"
[[ "$output" == *"spec"* ]] || fail "the refusal does not name spec: $output"
[[ "$output" != *"less than or equal to"* ]] || fail "replicas 3 was refused by a schema limit, not by a CEL rule: $output"

# Create: the rule must not refuse what is allowed.
for spec in \
  '{"team":"outpost","size":"small","replicas":2,"contact":"lead@outpost.starfleet.io"}' \
  '{"team":"outpost","size":"small","contact":"lead@outpost.starfleet.io"}' \
  '{"team":"outpost","size":"medium","replicas":4,"contact":"lead@outpost.starfleet.io"}' \
  '{"team":"outpost","size":"large","replicas":5,"contact":"lead@outpost.starfleet.io"}'; do
  output=$(dry_run_create "$spec") || fail "the API server refused a valid object: $spec ($output)"
done

# Update: the same rule runs on updates. alpha is small with 2 replicas.
output=$(dry_run_patch '{"spec":{"replicas":3}}') && fail "the API server accepted an update of alpha to 3 replicas while it is small"
output=$(dry_run_patch '{"spec":{"size":"medium","replicas":4}}') || fail "the API server refused an update of alpha to medium with 4 replicas: $output"

# Transition rule: team cannot change, other fields can.
output=$(dry_run_patch '{"spec":{"team":"starfleet"}}') && fail "the API server accepted a change of spec.team"
[[ "$output" == *"spec.team"* ]] || fail "the change of team was refused, but the error does not name spec.team: $output"
output=$(dry_run_patch '{"spec":{"contact":"ops@outpost.starfleet.io"}}') || fail "the API server refused an update of spec.contact: $output"
output=$(dry_run_patch '{"spec":{"team":"outpost"}}') || fail "the API server refused an update that keeps spec.team the same: $output"
# The transition rule must not run on create: a new object may have any valid team.
output=$(dry_run_create '{"team":"starfleet","size":"medium","contact":"lead@outpost.starfleet.io"}') || fail "the API server refused a new object with another team: $output"

echo "PASS: the CEL rules refuse a small environment with more than 2 replicas and a change of team"
