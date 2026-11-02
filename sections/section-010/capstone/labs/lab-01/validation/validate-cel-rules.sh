#!/usr/bin/env bash
# Grades the CEL rules with server-side dry-run patches on the two original objects:
#   orders-db  (postgres, 50 GB, 1 replica) and billing-db (mysql, 10 GB, 1 replica).
# Rules are checked through both versions. A rule that blocks every storage change, or a
# fixed minimum instead of a transition rule, fails one of the accepted controls.
set -u

NS="outpost"
CACHE=$(mktemp -d)
trap 'rm -rf "$CACHE"' EXIT
k() { kubectl --cache-dir="$CACHE" "$@"; }
fail() { echo "FAIL: $*"; exit 1; }

dry_patch() { # version, name, json
  k -n "$NS" patch "databases.$1.platform.starfleet.io" "$2" --type merge --dry-run=server -p "$3" >/dev/null 2>&1
}
must_accept() { dry_patch "$1" "$2" "$4" || fail "$1: $2 refused a valid change ($3)"; }
must_reject() { dry_patch "$1" "$2" "$4" && fail "$1: $2 accepted a forbidden change ($3)"; return 0; }

for version in v1 v1alpha1; do
  k -n "$NS" get "databases.$version.platform.starfleet.io" orders-db billing-db >/dev/null 2>&1 \
    || fail "$version: cannot read orders-db and billing-db; the original objects must stay"

  # Transition rule on storageGB: grow is fine, same is fine, shrink is refused.
  must_accept "$version" orders-db  "storage 50 -> 100"        '{"spec":{"storageGB":100}}'
  must_accept "$version" orders-db  "storage 50 -> 50"         '{"spec":{"storageGB":50}}'
  must_reject "$version" orders-db  "storage 50 -> 49"         '{"spec":{"storageGB":49}}'
  must_reject "$version" orders-db  "storage 50 -> 20"         '{"spec":{"storageGB":20}}'
  must_accept "$version" billing-db "storage 10 -> 20"         '{"spec":{"storageGB":20}}'
  must_reject "$version" billing-db "storage 10 -> 5"          '{"spec":{"storageGB":5}}'

  # Transition rule on team: a change is refused.
  must_reject "$version" orders-db  "team orders -> starfleet"  '{"spec":{"team":"starfleet"}}'
  must_accept "$version" orders-db  "team orders -> orders"     '{"spec":{"team":"orders"}}'

  # Cross-field rule: more than one replica needs 20 GB or more.
  must_accept "$version" orders-db  "3 replicas on 50 GB"       '{"spec":{"replicas":3}}'
  must_reject "$version" billing-db "3 replicas on 10 GB"       '{"spec":{"replicas":3}}'
  must_accept "$version" billing-db "1 replica on 10 GB"        '{"spec":{"replicas":1}}'
  must_accept "$version" billing-db "3 replicas and 20 GB in one write" '{"spec":{"replicas":3,"storageGB":20}}'
done

echo "PASS: storage can grow but not shrink, team is immutable, and more than 1 replica needs 20 GB, in both versions"
