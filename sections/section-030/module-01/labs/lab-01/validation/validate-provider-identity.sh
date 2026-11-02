#!/usr/bin/env bash
# Grades the provider identity: runtimeConfigRef -> DeploymentRuntimeConfig with the fixed
# ServiceAccount name, and a running provider pod that really uses that ServiceAccount.
# A hand-edited Deployment passes the pod check but fails the runtimeConfigRef check.
set -u

PROVIDER="provider-kubernetes"
WANT_SA="provider-kubernetes"
NS="crossplane-system"
fail() { echo "FAIL: $*"; exit 1; }

config_name=$(kubectl get provider.pkg.crossplane.io "$PROVIDER" -o jsonpath='{.spec.runtimeConfigRef.name}' 2>/dev/null)
[[ -n "$config_name" ]] || fail "the Provider has no spec.runtimeConfigRef; set it to a DeploymentRuntimeConfig"

kubectl get deploymentruntimeconfig.pkg.crossplane.io "$config_name" >/dev/null 2>&1 \
  || fail "the DeploymentRuntimeConfig '$config_name' named by runtimeConfigRef does not exist"

sa_name=$(kubectl get deploymentruntimeconfig.pkg.crossplane.io "$config_name" \
  -o jsonpath='{.spec.serviceAccountTemplate.metadata.name}')
[[ "$sa_name" == "$WANT_SA" ]] \
  || fail "DeploymentRuntimeConfig '$config_name' sets the ServiceAccount name to '$sa_name', expected $WANT_SA"

kubectl -n "$NS" get serviceaccount "$WANT_SA" >/dev/null 2>&1 || fail "the ServiceAccount $WANT_SA does not exist in $NS"

# Wait for a running provider pod that uses the fixed ServiceAccount (a rollout can take a moment).
found=""
for _ in $(seq 1 24); do
  while IFS='|' read -r name phase deleting sa; do
    [[ "$name" == provider-kubernetes-* ]] || continue
    [[ -z "$deleting" && "$phase" == "Running" && "$sa" == "$WANT_SA" ]] && found="$name"
  done < <(kubectl -n "$NS" get pods \
    -o jsonpath='{range .items[*]}{.metadata.name}{"|"}{.status.phase}{"|"}{.metadata.deletionTimestamp}{"|"}{.spec.serviceAccountName}{"\n"}{end}')
  [[ -n "$found" ]] && break
  sleep 5
done
[[ -n "$found" ]] || fail "no running provider-kubernetes pod in $NS uses the ServiceAccount $WANT_SA"

echo "PASS: pod $found runs as the ServiceAccount $WANT_SA, set through the DeploymentRuntimeConfig $config_name"
