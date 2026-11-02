#!/usr/bin/env bash
# Behaviour check: the tenant identity really can file and read requests.
# A server-side dry run runs authorization and schema validation, but stores
# nothing.
set -uo pipefail
TENANT=(--as outpost-dev --as-group outpost-team)
fail=0

for verb in get list watch; do
  answer=$(kubectl auth can-i "$verb" teamenvironments.platform.starfleet.io -n outpost "${TENANT[@]}" 2>/dev/null)
  if [ "$answer" = "yes" ]; then
    echo "PASS: outpost-team can $verb teamenvironments in outpost"
  else
    echo "FAIL: outpost-team cannot $verb teamenvironments in outpost"; fail=1
  fi
done

if kubectl -n outpost "${TENANT[@]}" create --dry-run=server -f - >/dev/null 2>&1 <<'YAML'
apiVersion: platform.starfleet.io/v1alpha1
kind: TeamEnvironment
metadata:
  name: grader-probe
  namespace: outpost
spec:
  team: outpost
YAML
then
  echo "PASS: outpost-dev can create a TeamEnvironment in outpost"
else
  echo "FAIL: outpost-dev cannot create a TeamEnvironment in outpost"; fail=1
fi
exit $fail
