#!/usr/bin/env bash
# Check 1: the group outpost-team may file and read TeamEnvironments in outpost
# and nothing else. Each denied line rejects a plausible wrong fix:
#   - binding edit, view or cluster-admin allows Deployments or Secrets
#   - a Role with update, patch or delete allows changing an accepted request
#   - a RoleBinding for the user only (not the group) fails the other-member line
#   - a ClusterRoleBinding allows the other namespaces
set -uo pipefail
TE=teamenvironments.platform.starfleet.io
fail=0

pass_line() { echo "PASS: $1"; }
fail_line() { echo "FAIL: $1"; fail=1; }

# tenant_can <verb> <resource> <namespace> <user>: prints yes or no for a member of outpost-team.
tenant_can() {
  kubectl auth can-i "$1" "$2" -n "$3" --as "$4" --as-group outpost-team 2>/dev/null
}

for verb in create get list watch; do
  if [ "$(tenant_can "$verb" "$TE" outpost outpost-dev)" = "yes" ]; then
    pass_line "outpost-team can $verb teamenvironments in outpost"
  else
    fail_line "outpost-team cannot $verb teamenvironments in outpost"
  fi
done

# A second member of the group must have the same rights: the binding names the group.
if [ "$(tenant_can create "$TE" outpost second-member)" = "yes" ]; then
  pass_line "another member of outpost-team can create teamenvironments (the binding names the group)"
else
  fail_line "another member of outpost-team cannot create teamenvironments: bind the group outpost-team, not the user outpost-dev"
fi

for verb in update patch delete deletecollection; do
  if [ "$(tenant_can "$verb" "$TE" outpost outpost-dev)" = "no" ]; then
    pass_line "outpost-team cannot $verb teamenvironments"
  else
    fail_line "outpost-team can $verb teamenvironments: allow only create, get, list and watch"
  fi
done

for item in deployments.apps services pods secrets configmaps rolebindings.rbac.authorization.k8s.io; do
  if [ "$(tenant_can create "$item" outpost outpost-dev)" = "no" ] \
    && [ "$(tenant_can get "$item" outpost outpost-dev)" = "no" ]; then
    pass_line "outpost-team can neither create nor get $item in outpost"
  else
    fail_line "outpost-team can create or get $item in outpost: the tenant may only request a TeamEnvironment"
  fi
done

for namespace in starfleet default; do
  if [ "$(tenant_can create "$TE" "$namespace" outpost-dev)" = "no" ]; then
    pass_line "outpost-team cannot create teamenvironments in $namespace"
  else
    fail_line "outpost-team can create teamenvironments in $namespace: use a Role and RoleBinding in outpost, not a cluster-wide binding"
  fi
done

# A user without the group gets nothing.
if [ "$(kubectl auth can-i create "$TE" -n outpost --as someone-else 2>/dev/null)" = "no" ]; then
  pass_line "a user outside the group cannot create teamenvironments"
else
  fail_line "a user outside outpost-team can create teamenvironments"
fi

# The server runs authorization and the schema on a dry run and stores nothing.
if kubectl -n outpost --as outpost-dev --as-group outpost-team create --dry-run=server -f - >/dev/null 2>&1 <<YAML
apiVersion: platform.starfleet.io/v1alpha1
kind: TeamEnvironment
metadata:
  name: grader-probe
  namespace: outpost
spec:
  team: grader
YAML
then
  pass_line "outpost-dev can file a TeamEnvironment in outpost (server-side dry run)"
else
  fail_line "outpost-dev cannot file a TeamEnvironment in outpost"
fi
exit $fail
