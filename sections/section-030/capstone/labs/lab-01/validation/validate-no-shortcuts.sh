#!/usr/bin/env bash
# Grader: rejects the plausible wrong fixes. Do not give the provider cluster-admin, do not
# loosen the schema with x-kubernetes-preserve-unknown-fields, do not add a second
# provider configuration, and do not create the Deployment, the Service or an Object by hand.
set -uo pipefail
fail() { echo "FAIL: no-shortcuts - $1"; exit 1; }

names=$(kubectl get clusterproviderconfigs.kubernetes.m.crossplane.io -o name 2>/dev/null | sort | tr '\n' ' ')
names="$names$(kubectl get providerconfigs.kubernetes.m.crossplane.io -A -o name 2>/dev/null | sort | tr '\n' ' ')"
[ "$names" = "clusterproviderconfig.kubernetes.m.crossplane.io/in-cluster " ] \
  || fail "expected only the ClusterProviderConfig in-cluster, found: ${names:-none}"

admins=$(kubectl get clusterrolebindings \
  -o jsonpath='{range .items[?(@.roleRef.name=="cluster-admin")]}{range .subjects[*]}{.name}{"\n"}{end}{end}' 2>/dev/null)
if printf '%s\n' "$admins" | grep -Fxq 'provider-kubernetes'; then
  fail "the ServiceAccount provider-kubernetes is bound to cluster-admin; give it a Role in outpost instead"
fi

if kubectl get xrd teamenvironments.platform.starfleet.io -o yaml 2>/dev/null | grep -q 'x-kubernetes-preserve-unknown-fields'; then
  fail "the XRD uses x-kubernetes-preserve-unknown-fields; declare the fields in the schema instead"
fi

refs=$(kubectl -n outpost get teamenvironment scout-env \
  -o jsonpath='{range .spec.crossplane.resourceRefs[*]}{.name}{"\n"}{end}' 2>/dev/null | sort | tr '\n' ' ')
objects=$(kubectl get objects.kubernetes.m.crossplane.io -A \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null | sort | tr '\n' ' ')
if [ -z "$refs" ] || [ "$refs" != "$objects" ]; then
  fail "the Object resources in the cluster (${objects:-none}) are not exactly the ones Crossplane composed (${refs:-none})"
fi
kinds=$(kubectl -n outpost get objects.kubernetes.m.crossplane.io \
  -o jsonpath='{range .items[*]}{.spec.forProvider.manifest.kind}{"\n"}{end}' 2>/dev/null | sort | tr '\n' ' ')
[ "$kinds" = "Deployment Service " ] || fail "the composed Objects wrap '${kinds}', expected one Deployment and one Service"

echo "PASS: no-shortcuts - one ClusterProviderConfig, no cluster-admin, a strict schema, only composed Objects"
