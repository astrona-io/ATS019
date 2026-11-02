#!/usr/bin/env bash
# Grader: provider-kubernetes 1.4.1 is installed and healthy, its pod runs under the
# ServiceAccount provider-kubernetes, and the only provider configuration is the
# ClusterProviderConfig in-cluster with the injected identity.
set -uo pipefail
fail() { echo "FAIL: provider - $1"; exit 1; }

pkg=$(kubectl get provider.pkg.crossplane.io provider-kubernetes -o jsonpath='{.spec.package}' 2>/dev/null)
[ -n "$pkg" ] || fail "no Provider named provider-kubernetes"
[ "$pkg" = "xpkg.crossplane.io/crossplane-contrib/provider-kubernetes:v1.4.1" ] \
  || fail "the Provider uses the package '${pkg}', expected xpkg.crossplane.io/crossplane-contrib/provider-kubernetes:v1.4.1"

installed=$(kubectl get provider.pkg.crossplane.io provider-kubernetes -o jsonpath='{.status.conditions[?(@.type=="Installed")].status}' 2>/dev/null)
healthy=$(kubectl get provider.pkg.crossplane.io provider-kubernetes -o jsonpath='{.status.conditions[?(@.type=="Healthy")].status}' 2>/dev/null)
if [ "$installed" != "True" ] || [ "$healthy" != "True" ]; then
  fail "the Provider is Installed=${installed:-missing} Healthy=${healthy:-missing}, expected both True"
fi

kubectl -n crossplane-system get serviceaccount provider-kubernetes >/dev/null 2>&1 \
  || fail "no ServiceAccount provider-kubernetes in crossplane-system; set it with a DeploymentRuntimeConfig"
pod_account=$(kubectl -n crossplane-system get pods \
  -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.serviceAccountName}{"\n"}{end}' 2>/dev/null \
  | grep '^provider-kubernetes-' | head -n 1 | cut -d' ' -f2)
[ "$pod_account" = "provider-kubernetes" ] \
  || fail "the provider pod runs under the ServiceAccount '${pod_account:-none}', expected provider-kubernetes"

poll_args=$(kubectl get deploymentruntimeconfigs.pkg.crossplane.io provider-kubernetes \
  -o jsonpath='{.spec.deploymentTemplate.spec.template.spec.containers[*].args}' 2>/dev/null)
case "$poll_args" in
  *--poll=*) ;;
  *) fail "the provider has no --poll argument in its DeploymentRuntimeConfig; set --poll=30s so Object status is refreshed" ;;
esac

source=$(kubectl get clusterproviderconfigs.kubernetes.m.crossplane.io in-cluster \
  -o jsonpath='{.spec.credentials.source}' 2>/dev/null)
[ "$source" = "InjectedIdentity" ] \
  || fail "no ClusterProviderConfig in-cluster with credentials.source InjectedIdentity (found '${source:-none}')"

echo "PASS: provider - provider-kubernetes 1.4.1 is healthy and in-cluster uses the injected identity"
