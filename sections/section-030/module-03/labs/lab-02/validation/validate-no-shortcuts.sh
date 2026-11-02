#!/usr/bin/env bash
# Grader: rejects the plausible wrong fixes. Do not create a ProviderConfig
# that matches the typo, do not widen the provider's RBAC, and do not create the
# composed objects by hand.
set -uo pipefail

names=$(kubectl get clusterproviderconfigs.kubernetes.m.crossplane.io -o name 2>/dev/null | sort | tr '\n' ' ')
names="$names$(kubectl get providerconfigs.kubernetes.m.crossplane.io -A -o name 2>/dev/null | sort | tr '\n' ' ')"
if [ "$names" != "clusterproviderconfig.kubernetes.m.crossplane.io/in-cluster " ]; then
  echo "FAIL: no-shortcuts - expected only the ClusterProviderConfig in-cluster, found: ${names:-none}"
  exit 1
fi

for check in "delete namespaces" "create clusterrolebindings.rbac.authorization.k8s.io" "delete nodes"; do
  answer=$(kubectl auth can-i $check \
    --as=system:serviceaccount:crossplane-system:provider-kubernetes 2>/dev/null || true)
  if [ "$answer" = "yes" ]; then
    echo "FAIL: no-shortcuts - the provider service account can ${check} cluster-wide; do not widen its access"
    exit 1
  fi
done

refs=$(kubectl -n outpost get teamenvironment scout-env \
  -o jsonpath='{range .spec.crossplane.resourceRefs[*]}{.name}{"\n"}{end}' 2>/dev/null | sort | tr '\n' ' ')
objects=$(kubectl -n outpost get objects.kubernetes.m.crossplane.io \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null | sort | tr '\n' ' ')
if [ -z "$refs" ] || [ "$refs" != "$objects" ]; then
  echo "FAIL: no-shortcuts - the Object resources in outpost (${objects}) are not exactly the ones Crossplane composed (${refs})"
  exit 1
fi
echo "PASS: no-shortcuts - one ProviderConfig, no widened RBAC, only composed Object resources"
