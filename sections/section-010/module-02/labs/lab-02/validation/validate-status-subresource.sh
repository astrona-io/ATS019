#!/usr/bin/env bash
# Grades the status subresource: the CRD enables it, the /status endpoint answers, status
# was written for alpha and beta, and a normal write does NOT change status.
set -u

CRD="teamenvironments.platform.starfleet.io"
fail() { echo "FAIL: $*"; exit 1; }

kubectl get crd "$CRD" >/dev/null 2>&1 || fail "the CRD $CRD does not exist"

has_status=$(kubectl get crd "$CRD" -o jsonpath='{.spec.versions[?(@.name=="v1")].subresources}')
echo "$has_status" | grep -q '"status"' || fail "the v1 version of the CRD does not enable the status subresource"

# The /status endpoint must answer (a retry covers the moment after the CRD change).
ok=""
for _ in $(seq 1 30); do
  if kubectl -n outpost get --raw /apis/platform.starfleet.io/v1/namespaces/outpost/teamenvironments/alpha/status >/dev/null 2>&1; then ok=yes; break; fi
  sleep 2
done
[[ -n "$ok" ]] || fail "the /status endpoint of alpha does not answer"

read_status() { kubectl -n outpost get teamenvironment.v1.platform.starfleet.io "$1" -o jsonpath='{.status.readyReplicas}{" "}{.status.phase}' 2>/dev/null; }
[[ "$(read_status alpha)" == "2 Ready" ]] || fail "alpha status is '$(read_status alpha)', expected '2 Ready' (readyReplicas 2, phase Ready)"
[[ "$(read_status beta)" == "4 Ready" ]] || fail "beta status is '$(read_status beta)', expected '4 Ready' (readyReplicas 4, phase Ready)"

# Behaviour: a normal write must ignore status. A server-side dry run returns the object
# as the API server would store it.
phase_after=$(kubectl -n outpost patch teamenvironment.v1.platform.starfleet.io beta --type merge \
  --dry-run=server -p '{"status":{"phase":"WrittenBySpecEndpoint"}}' \
  -o jsonpath='{.status.phase}' 2>/dev/null)
[[ "$phase_after" == "Ready" ]] \
  || fail "a normal write changed status.phase to '$phase_after'; the status subresource must ignore status on the main endpoint"

echo "PASS: the status subresource is enabled, alpha and beta have status, and a normal write cannot change it"
