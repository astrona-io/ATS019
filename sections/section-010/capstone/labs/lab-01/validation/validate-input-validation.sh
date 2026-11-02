#!/usr/bin/env bash
# Grades the schema through both served versions with server-side dry runs, so nothing is stored.
# Each rejected case differs from the accepted control in one value, so a rejection cannot come
# from an unrelated mistake. v1alpha1 is checked too: an old version with a weak schema would let
# old clients bypass the rules.
set -u

GROUP="platform.starfleet.io"
NS="outpost"
CACHE=$(mktemp -d)
trap 'rm -rf "$CACHE"' EXIT
k() { kubectl --cache-dir="$CACHE" "$@"; }
fail() { echo "FAIL: $*"; exit 1; }

manifest() { # version, body
  printf 'apiVersion: %s/%s\nkind: Database\nmetadata:\n  name: grader-probe\n  namespace: %s\n%s\n' \
    "$GROUP" "$1" "$NS" "$2"
}
dry_create() { manifest "$1" "$2" | k create --dry-run=server --validate=strict -f - >/dev/null 2>&1; }
must_accept() { dry_create "$1" "$3" || fail "$1: the API server refused a valid Database ($2)"; }
must_reject() { dry_create "$1" "$3" && fail "$1: the API server accepted bad input ($2)"; return 0; }

LONG_TEAM=$(printf 'a%.0s' $(seq 1 31))

for version in v1 v1alpha1; do
  must_accept "$version" "valid control" $'spec:\n  team: grader\n  engine: postgres\n  storageGB: 30\n  replicas: 2'
  must_accept "$version" "only the required fields" $'spec:\n  team: grader\n  engine: mysql'

  defaults=$(manifest "$version" $'spec:\n  team: grader\n  engine: postgres' \
    | k create --dry-run=server --validate=strict -f - -o jsonpath='{.spec.storageGB}/{.spec.replicas}' 2>/dev/null)
  [[ "$defaults" == "10/1" ]] || fail "$version: defaults must give storageGB 10 and replicas 1, got '$defaults'"

  must_reject "$version" "no spec"                    ''
  must_reject "$version" "missing engine"             $'spec:\n  team: grader'
  must_reject "$version" "missing team"               $'spec:\n  engine: postgres'
  must_reject "$version" "engine oracle"              $'spec:\n  team: grader\n  engine: oracle'
  must_reject "$version" "empty team"                 $'spec:\n  team: ""\n  engine: postgres'
  must_reject "$version" "team longer than 30"        "spec:
  team: $LONG_TEAM
  engine: postgres"
  must_reject "$version" "storageGB 0"                $'spec:\n  team: grader\n  engine: postgres\n  storageGB: 0'
  must_reject "$version" "storageGB 501"              $'spec:\n  team: grader\n  engine: postgres\n  storageGB: 501'
  must_reject "$version" "storageGB as text"          $'spec:\n  team: grader\n  engine: postgres\n  storageGB: ten'
  must_reject "$version" "replicas 0"                 $'spec:\n  team: grader\n  engine: postgres\n  replicas: 0'
  must_reject "$version" "replicas 6"                 $'spec:\n  team: grader\n  engine: postgres\n  storageGB: 100\n  replicas: 6'
  must_reject "$version" "misspelled field replcas"   $'spec:\n  team: grader\n  engine: postgres\n  replcas: 2'
  must_reject "$version" "unknown field colour"       $'spec:\n  team: grader\n  engine: postgres\n  colour: blue'
  must_reject "$version" "3 replicas with default 10 GB" $'spec:\n  team: grader\n  engine: postgres\n  replicas: 3'
  must_accept "$version" "3 replicas with 20 GB" $'spec:\n  team: grader\n  engine: postgres\n  storageGB: 20\n  replicas: 3'
done

echo "PASS: v1 and v1alpha1 apply the defaults and refuse missing, out-of-range, misspelled and unknown input"
