#!/usr/bin/env bash
# Grades the Provider object: pinned package, Installed and Healthy, CRDs present.
set -u

PROVIDER="provider-kubernetes"
WANT_SUFFIX="crossplane-contrib/provider-kubernetes:v1.4.1"
fail() { echo "FAIL: $*"; exit 1; }
condition() {
  kubectl get provider.pkg.crossplane.io "$PROVIDER" \
    -o jsonpath="{.status.conditions[?(@.type==\"$1\")].status}" 2>/dev/null
}

kubectl get provider.pkg.crossplane.io "$PROVIDER" >/dev/null 2>&1 || fail "no Provider named $PROVIDER"

package=$(kubectl get provider.pkg.crossplane.io "$PROVIDER" -o jsonpath='{.spec.package}')
[[ "$package" == *"$WANT_SUFFIX" ]] || fail "spec.package is '$package', expected xpkg.crossplane.io/$WANT_SUFFIX"

# The package manager can need a moment to report Healthy after a fresh apply.
installed=""; healthy=""
for _ in $(seq 1 12); do
  installed=$(condition Installed)
  healthy=$(condition Healthy)
  [[ "$installed" == "True" && "$healthy" == "True" ]] && break
  sleep 5
done
[[ "$installed" == "True" ]] || fail "Provider is not Installed (status '$installed')"
[[ "$healthy" == "True" ]] || fail "Provider is not Healthy (status '$healthy')"

for crd in objects.kubernetes.m.crossplane.io providerconfigs.kubernetes.m.crossplane.io; do
  kubectl get crd "$crd" >/dev/null 2>&1 || fail "CRD $crd is missing"
done

echo "PASS: provider-kubernetes v1.4.1 is Installed and Healthy and its CRDs exist"
