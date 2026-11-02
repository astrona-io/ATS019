#!/usr/bin/env bash
# Grades the scale subresource: the exact paths in the CRD, the Scale object the API server
# returns for alpha and beta, the replica count of beta, and the schema limit on scaling.
set -u

CRD="teamenvironments.platform.starfleet.io"
fail() { echo "FAIL: $*"; exit 1; }

kubectl get crd "$CRD" >/dev/null 2>&1 || fail "the CRD $CRD does not exist"

spec_path=$(kubectl get crd "$CRD" -o jsonpath='{.spec.versions[?(@.name=="v1")].subresources.scale.specReplicasPath}')
status_path=$(kubectl get crd "$CRD" -o jsonpath='{.spec.versions[?(@.name=="v1")].subresources.scale.statusReplicasPath}')
[[ "$spec_path" == ".spec.replicas" ]] || fail "specReplicasPath is '$spec_path', expected .spec.replicas"
[[ "$status_path" == ".status.readyReplicas" ]] || fail "statusReplicasPath is '$status_path', expected .status.readyReplicas"

scale_of() { kubectl -n outpost get --raw "/apis/platform.starfleet.io/v1/namespaces/outpost/teamenvironments/$1/scale" 2>/dev/null; }

# Wait for the endpoint after the CRD change.
for _ in $(seq 1 30); do
  scale_of alpha | grep -q '"kind":"Scale"' && break
  sleep 2
done

alpha_scale=$(scale_of alpha)
echo "$alpha_scale" | grep -q '"kind":"Scale"' || fail "the /scale endpoint of alpha does not return a Scale object"
echo "$alpha_scale" | grep -q '"spec":{"replicas":2}' || fail "alpha: Scale spec.replicas is not 2; got: $alpha_scale"
echo "$alpha_scale" | grep -q '"status":{"replicas":2' || fail "alpha: Scale status.replicas is not 2; got: $alpha_scale"

beta_scale=$(scale_of beta)
echo "$beta_scale" | grep -q '"spec":{"replicas":4}' || fail "beta: Scale spec.replicas is not 4; beta must be scaled to 4 replicas; got: $beta_scale"
echo "$beta_scale" | grep -q '"status":{"replicas":4' || fail "beta: Scale status.replicas is not 4; got: $beta_scale"

beta_spec=$(kubectl -n outpost get teamenvironment.v1.platform.starfleet.io beta -o jsonpath='{.spec.team}{" "}{.spec.size}{" "}{.spec.replicas}' 2>/dev/null)
[[ "$beta_spec" == "outpost medium 4" ]] || fail "beta spec is '$beta_spec', expected 'outpost medium 4'"

# The schema limit must still apply to the scale endpoint (the maximum is 5).
if kubectl -n outpost scale teamenvironment.v1.platform.starfleet.io alpha --replicas=9 --dry-run=server >/dev/null 2>&1; then
  fail "scaling alpha to 9 replicas was accepted; the schema maximum of 5 must still apply"
fi

echo "PASS: the scale paths are .spec.replicas and .status.readyReplicas, alpha is 2 of 2, beta is scaled to 4 of 4, the schema limit still applies"
