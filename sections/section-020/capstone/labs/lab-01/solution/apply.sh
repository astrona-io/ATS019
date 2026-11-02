#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`. Keep in step with solution.md.
set -euo pipefail
cd "$(dirname "$0")"

# 1. The operator: create the Secret it reads, then point the resource at the real ServiceAccount.
kubectl apply -f solution.yaml
kubectl -n outpost patch prometheus outpost-metrics --type merge -p '{"spec":{"serviceAccountName":"prometheus"}}'

# 2. Ownership: add one owner reference with the real UID to each environment ConfigMap.
team_env_uid="$(kubectl -n outpost get teamenvironment scout-env -o jsonpath='{.metadata.uid}')"
for name in scout-env-settings scout-env-limits; do
  kubectl -n outpost patch configmap "$name" --type merge -p \
    "{\"metadata\":{\"ownerReferences\":[{\"apiVersion\":\"platform.starfleet.io/v1alpha1\",\"kind\":\"TeamEnvironment\",\"name\":\"scout-env\",\"uid\":\"${team_env_uid}\",\"blockOwnerDeletion\":true}]}}"
done

# 3. The stuck deletion: the Role is fixed above, so now start the suspended worker.
kubectl -n outpost patch job scout-cleanup --type merge -p '{"spec":{"suspend":false}}'
