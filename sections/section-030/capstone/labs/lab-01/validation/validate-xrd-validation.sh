#!/usr/bin/env bash
# Grader: the schema refuses bad requests and fills in defaults. Every case is a
# server-side dry run, so nothing is stored. A schema loosened with
# x-kubernetes-preserve-unknown-fields fails the unknown-field case.
set -uo pipefail
fail() { echo "FAIL: xrd-validation - $1"; exit 1; }

request() { # extra spec lines
  printf 'apiVersion: platform.starfleet.io/v1alpha1\nkind: TeamEnvironment\nmetadata:\n  name: validate-case\n  namespace: outpost\nspec:\n%s\n' "$1"
}
expect_refused() { # label, spec lines
  if request "$2" | kubectl create --dry-run=server -f - >/dev/null 2>&1; then
    fail "the API server accepted a request with $1"
  fi
}

expect_refused "no team" "  size: small"
expect_refused "replicas 0" "  team: outpost
  replicas: 0"
expect_refused "replicas 4" "  team: outpost
  replicas: 4"
expect_refused "size huge" "  team: outpost
  size: huge"
expect_refused "an unknown field" "  team: outpost
  colour: red"

out=$(request "  team: outpost" | kubectl create --dry-run=server -o jsonpath='{.spec.size}/{.spec.replicas}' -f - 2>&1) \
  || fail "a request with only team was refused: ${out}"
[ "$out" = "small/1" ] || fail "the defaults are '${out}', expected size small and replicas 1 (small/1)"

out=$(request "  team: outpost
  size: large
  replicas: 3
  contact: crew@example.com" | kubectl create --dry-run=server -o jsonpath='{.spec.size}/{.spec.replicas}/{.spec.contact}' -f - 2>&1) \
  || fail "a request with every field set was refused: ${out}"
[ "$out" = "large/3/crew@example.com" ] || fail "values were changed or pruned: '${out}'"

echo "PASS: xrd-validation - bad requests are refused and the defaults are size small, replicas 1"
