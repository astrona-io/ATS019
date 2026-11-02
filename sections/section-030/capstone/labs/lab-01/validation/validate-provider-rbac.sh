#!/usr/bin/env bash
# Grader: the permission model, not the objects. The provider ServiceAccount must manage
# Deployments and Services in outpost and must not be able to do more. This rejects
# cluster-admin, a wildcard rule, a ClusterRoleBinding with cluster-wide access and a rule
# for another namespace.
set -uo pipefail
SA="system:serviceaccount:crossplane-system:provider-kubernetes"
fail() { echo "FAIL: provider-rbac - $1"; exit 1; }
can() { kubectl auth can-i "$@" --as="$SA" 2>/dev/null; }

for resource in deployments.apps services; do
  for verb in get create update delete; do
    [ "$(can "$verb" "$resource" -n outpost)" = "yes" ] \
      || fail "the provider cannot ${verb} ${resource} in outpost"
  done
done

[ "$(can create deployments.apps -n starfleet)" = "no" ] \
  || fail "the provider can create Deployments in starfleet; grant access in outpost only"
[ "$(can create services -n starfleet)" = "no" ] \
  || fail "the provider can create Services in starfleet; grant access in outpost only"
[ "$(can list services --all-namespaces)" = "no" ] \
  || fail "the provider can list Services in all namespaces; use a Role and a RoleBinding in outpost"
[ "$(can list deployments.apps --all-namespaces)" = "no" ] \
  || fail "the provider can list Deployments in all namespaces; use a Role and a RoleBinding in outpost"
[ "$(can create pods -n outpost)" = "no" ] \
  || fail "the provider can create Pods in outpost; grant Deployments and Services only"
[ "$(can delete namespaces)" = "no" ] \
  || fail "the provider can delete namespaces; do not widen its access"
[ "$(can create clusterrolebindings.rbac.authorization.k8s.io)" = "no" ] \
  || fail "the provider can create ClusterRoleBindings; do not give it cluster-admin"
[ "$(can '*' '*' -n outpost)" = "no" ] \
  || fail "the provider can do everything in outpost; do not use a wildcard rule"

echo "PASS: provider-rbac - the provider manages Deployments and Services in outpost and nothing wider"
