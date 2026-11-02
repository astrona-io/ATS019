#!/usr/bin/env bash
# Check: the schema refuses bad requests. Each case is a server-side dry run.
# A schema loosened with x-kubernetes-preserve-unknown-fields fails the last case.
set -uo pipefail
fail() { echo "FAIL: $1"; exit 1; }

expect_refused() { # label, spec lines
  local label="$1" spec="$2" out
  out="$(printf 'apiVersion: platform.starfleet.io/v1alpha1\nkind: ProbeEnvironment\nmetadata:\n  name: validate-bad\n  namespace: outpost\nspec:\n%s\n' "$spec" | kubectl create --dry-run=server -f - 2>&1)"
  if [ $? -eq 0 ]; then
    fail "the API server accepted a request with $label"
  fi
}

expect_refused "no owner" "  tier: dev"
expect_refused "instances 0" "  owner: drifter
  instances: 0"
expect_refused "instances 6" "  owner: drifter
  instances: 6"
expect_refused "tier test" "  owner: drifter
  tier: test"
expect_refused "an unknown field" "  owner: drifter
  colour: red"

echo "PASS: missing owner, instances 0 and 6, tier test and unknown fields are refused"
