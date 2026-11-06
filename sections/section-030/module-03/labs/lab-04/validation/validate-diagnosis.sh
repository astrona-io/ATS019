#!/usr/bin/env bash
# Match the report to the observed initial condition and the live child identity.
set -euo pipefail
fail() { echo "FAIL: diagnosis - $*"; exit 1; }
baseline() { kubectl -n starfleet get configmap trace-baseline -o "jsonpath={.data.$1}"; }
report() { kubectl -n outpost get configmap trace-report -o "jsonpath={.data.$1}"; }
digest() { if command -v sha256sum >/dev/null 2>&1; then printf '%s' "$1" | sha256sum; else printf '%s' "$1" | shasum -a 256; fi | cut -d' ' -f1; }
kubectl -n outpost get configmap trace-report >/dev/null 2>&1 || fail "create trace-report"
# The baseline holds SHA-256 digests of the captured fields, not the values.
for field in kind name reason message; do
  expected=$(baseline "${field}Sha")
  [ -n "$expected" ] && [ "$(digest "$(report "$field")")" = "$expected" ] || fail "$field must match the original failing child condition"
done
object_name=$(report name)
[ "$(report kind)" = "$(kubectl -n outpost get objects.kubernetes.m.crossplane.io "$object_name" -o jsonpath='{.kind}')" ] || fail "kind differs from live child"
[ "$(baseline uid)" = "$(kubectl -n outpost get objects.kubernetes.m.crossplane.io "$object_name" -o jsonpath='{.metadata.uid}')" ] || fail "keep the original child"
request_uid=$(kubectl -n outpost get teamenvironment scout-env -o jsonpath='{.metadata.uid}')
[ "$request_uid" = "$(baseline requestUid)" ] || fail "keep the original request"
refs=$(kubectl -n outpost get teamenvironment scout-env -o jsonpath='{range .spec.crossplane.resourceRefs[*]}{.name}{"\n"}{end}')
printf '%s\n' "$refs" | grep -Fxq "$object_name" || fail "reported child is not referenced by scout-env"
owner_uid=$(kubectl -n outpost get objects.kubernetes.m.crossplane.io "$object_name" -o jsonpath='{.metadata.ownerReferences[?(@.controller==true)].uid}')
[ "$owner_uid" = "$request_uid" ] || fail "child must belong to the original request"
echo "PASS: diagnosis - report matches the captured condition and live child"
