#!/usr/bin/env bash
# Grades the permission model, not the Object: the provider ServiceAccount must be able to
# manage Services in outpost and must not be able to do more. This rejects cluster-admin,
# a ClusterRoleBinding with wide access, and a Service created by hand (the provider
# could not update or delete it). It checks only what the learner controls: the provider's
# own system ClusterRole already allows ConfigMaps, Secrets, Events and Leases everywhere,
# so those are not tested.
set -u

SA="system:serviceaccount:crossplane-system:provider-kubernetes"
fail() { echo "FAIL: $*"; exit 1; }
can() { kubectl auth can-i "$@" --as="$SA" 2>/dev/null; }

for verb in get create update delete; do
  [[ "$(can "$verb" services -n outpost)" == "yes" ]] \
    || fail "the provider ServiceAccount cannot $verb services in outpost"
done

[[ "$(can create services -n starfleet)" == "no" ]] \
  || fail "the provider can create Services in the namespace starfleet; grant access in outpost only"
[[ "$(can list services --all-namespaces)" == "no" ]] \
  || fail "the provider can list Services in all namespaces; use a Role and a RoleBinding in outpost"
[[ "$(can create deployments.apps -n outpost)" == "no" ]] \
  || fail "the provider can create Deployments in outpost; grant Service access only"
[[ "$(can '*' '*' -n outpost)" == "no" ]] \
  || fail "the provider can do everything in outpost; do not give it cluster-admin or a wildcard rule"

# No ClusterRoleBinding may give the ServiceAccount cluster-admin.
bound=$(kubectl get clusterrolebindings -o jsonpath='{range .items[?(@.roleRef.name=="cluster-admin")]}{range .subjects[*]}{.kind}{"/"}{.namespace}{"/"}{.name}{"\n"}{end}{end}' 2>/dev/null)
if grep -qx "ServiceAccount/crossplane-system/provider-kubernetes" <<<"$bound"; then
  fail "the provider ServiceAccount is bound to cluster-admin; remove that ClusterRoleBinding"
fi

echo "PASS: the provider may manage Services in outpost and nothing wider"
