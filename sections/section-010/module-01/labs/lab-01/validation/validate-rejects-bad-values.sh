#!/usr/bin/env bash
# Grades behaviour: the API server must refuse each bad TeamEnvironment, and the error must
# name the field that is wrong. Uses server-side dry runs, so nothing is stored.
set -u

fail() { echo "FAIL: $*"; exit 1; }

# Send a TeamEnvironment with the given spec (JSON) through a server-side dry-run create.
dry_run_create() {
  local spec="$1"
  printf '{"apiVersion":"platform.starfleet.io/v1alpha1","kind":"TeamEnvironment","metadata":{"name":"grader-check","namespace":"outpost"},"spec":%s}' "$spec" \
    | kubectl create --dry-run=server -f - -o name 2>&1
}

# The CRD update takes a moment to reach the API server: wait until the first bad value is refused.
for _ in $(seq 1 20); do
  dry_run_create '{"team":"outpost","size":"huge","contact":"lead@outpost.starfleet.io"}' >/dev/null && sleep 3 || break
done

# expect_rejected <label> <field path that the error must name> <spec JSON>
expect_rejected() {
  local label="$1" field="$2" spec="$3" output
  if output=$(dry_run_create "$spec"); then
    fail "the API server accepted $label"
  fi
  [[ "$output" == *"$field"* ]] || fail "$label was refused, but the error does not name $field: $output"
}

expect_rejected "size huge" "spec.size" '{"team":"outpost","size":"huge","contact":"lead@outpost.starfleet.io"}'
expect_rejected "replicas 50" "spec.replicas" '{"team":"outpost","size":"small","replicas":50,"contact":"lead@outpost.starfleet.io"}'
expect_rejected "replicas 0" "spec.replicas" '{"team":"outpost","size":"small","replicas":0,"contact":"lead@outpost.starfleet.io"}'
expect_rejected "replicas as a string" "spec.replicas" '{"team":"outpost","size":"small","replicas":"two","contact":"lead@outpost.starfleet.io"}'
expect_rejected "retentionDays 91" "spec.retentionDays" '{"team":"outpost","size":"small","retentionDays":91,"contact":"lead@outpost.starfleet.io"}'
expect_rejected "contact nobody" "spec.contact" '{"team":"outpost","size":"small","contact":"nobody"}'
expect_rejected "a missing team" "spec.team" '{"size":"small","contact":"lead@outpost.starfleet.io"}'
expect_rejected "a missing size" "spec.size" '{"team":"outpost","contact":"lead@outpost.starfleet.io"}'
expect_rejected "a missing contact" "spec.contact" '{"team":"outpost","size":"small"}'
expect_rejected "a team name of 31 characters" "spec.team" '{"team":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","size":"small","contact":"lead@outpost.starfleet.io"}'
expect_rejected "an empty team" "spec.team" '{"team":"","size":"small","contact":"lead@outpost.starfleet.io"}'

echo "PASS: the API server refuses a bad size, replicas, retentionDays, contact and missing required fields"
