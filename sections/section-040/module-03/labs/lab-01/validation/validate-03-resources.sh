#!/usr/bin/env bash
# Rejects the plausible wrong fixes: binding edit, view or cluster-admin, or a
# Role with a wildcard resource. Each of those allows at least one line below.
set -uo pipefail
TENANT=(--as outpost-dev --as-group outpost-team)
fail=0

check_denied() {
  local verb=$1 resource=$2
  local answer
  answer=$(kubectl auth can-i "$verb" "$resource" -n outpost "${TENANT[@]}" 2>/dev/null)
  if [ "$answer" = "no" ]; then
    echo "PASS: outpost-team cannot $verb $resource in outpost"
  else
    echo "FAIL: outpost-team can $verb $resource in outpost"; fail=1
  fi
}

check_denied create deployments.apps
check_denied create pods
check_denied create services
check_denied get secrets
check_denied list configmaps
check_denied create rolebindings.rbac.authorization.k8s.io
exit $fail
