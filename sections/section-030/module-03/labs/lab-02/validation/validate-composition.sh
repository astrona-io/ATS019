#!/usr/bin/env bash
# Grader: the fix is in the Composition itself. The Service must use the real
# ClusterProviderConfig, and the Deployment must still take its replicas from
# the request through a patch (a hard-coded 2 does not pass).
set -uo pipefail

res='.spec.pipeline[0].input.resources'
service_config=$(kubectl get composition teamenvironment \
  -o jsonpath="{${res}[?(@.name==\"service\")].base.spec.providerConfigRef.name}" 2>/dev/null)
patches=$(kubectl get composition teamenvironment \
  -o jsonpath="{range ${res}[?(@.name==\"deployment\")].patches[*]}{.fromFieldPath}{\" -> \"}{.toFieldPath}{\"\n\"}{end}" 2>/dev/null)

if [ "$service_config" != "in-cluster" ]; then
  echo "FAIL: composition - the service resource uses the ProviderConfig '${service_config:-none}', expected in-cluster"
  exit 1
fi
if ! printf '%s\n' "$patches" | grep -Fxq 'spec.replicas -> spec.forProvider.manifest.spec.replicas'; then
  echo "FAIL: composition - no patch copies spec.replicas to spec.forProvider.manifest.spec.replicas in the deployment resource"
  exit 1
fi
echo "PASS: composition - the Service uses in-cluster and the Deployment patches replicas from the request"
