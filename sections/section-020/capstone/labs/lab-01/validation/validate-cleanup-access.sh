#!/usr/bin/env bash
# Grades the permission model of the cleanup worker. It must be able to delete scout-cache
# and patch scout-settings and must not be able to do more. This rejects cluster-admin, a
# Role that allows deleting every ConfigMap, and a ClusterRoleBinding with wide access.
set -u

NS="outpost"
as="system:serviceaccount:$NS:scout-cleanup"
fail() { echo "FAIL: $*"; exit 1; }
can() { kubectl auth can-i "$@" --as="$as" 2>/dev/null; }

[[ "$(can delete configmap/scout-cache -n "$NS")" == "yes" ]] || fail "the ServiceAccount scout-cleanup cannot delete the ConfigMap scout-cache"
[[ "$(can patch configmap/scout-settings -n "$NS")" == "yes" ]] || fail "the ServiceAccount scout-cleanup cannot patch the ConfigMap scout-settings"

[[ "$(can delete configmaps -n "$NS")" == "no" ]] || fail "the ServiceAccount scout-cleanup can delete every ConfigMap in $NS; limit the rule with resourceNames"
[[ "$(can delete configmap/shared-notes -n "$NS")" == "no" ]] || fail "the ServiceAccount scout-cleanup can delete shared-notes"
[[ "$(can delete configmaps -n kube-system)" == "no" ]] || fail "the ServiceAccount scout-cleanup can delete ConfigMaps in kube-system"
[[ "$(can create deployments.apps -n "$NS")" == "no" ]] || fail "the ServiceAccount scout-cleanup can create Deployments"
[[ "$(can '*' '*' -n "$NS")" == "no" ]] || fail "the ServiceAccount scout-cleanup can do everything in $NS; do not give it cluster-admin"

echo "PASS: the cleanup ServiceAccount can delete scout-cache and patch scout-settings and nothing wider"
