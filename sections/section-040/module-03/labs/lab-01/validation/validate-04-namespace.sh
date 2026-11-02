#!/usr/bin/env bash
# The rights must end at the edge of outpost. A ClusterRoleBinding would make
# these checks fail.
set -uo pipefail
TENANT=(--as outpost-dev --as-group outpost-team)
fail=0

for namespace in starfleet default kube-system; do
  answer=$(kubectl auth can-i create teamenvironments.platform.starfleet.io -n "$namespace" "${TENANT[@]}" 2>/dev/null)
  if [ "$answer" = "no" ]; then
    echo "PASS: outpost-team cannot create teamenvironments in $namespace"
  else
    echo "FAIL: outpost-team can create teamenvironments in $namespace"; fail=1
  fi
done

answer=$(kubectl auth can-i list teamenvironments.platform.starfleet.io --all-namespaces "${TENANT[@]}" 2>/dev/null)
if [ "$answer" = "no" ]; then
  echo "PASS: outpost-team cannot list teamenvironments in all namespaces"
else
  echo "FAIL: outpost-team can list teamenvironments in all namespaces"; fail=1
fi
exit $fail
