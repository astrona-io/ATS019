#!/usr/bin/env bash
# The StatefulSet must carry the new flag, and the controller must have written it,
# not kubectl. A hand-edited StatefulSet shows a kubectl field manager.
set -u

fail() { echo "FAIL: $*"; exit 1; }
sts() { kubectl -n starfleet get statefulset prometheus-starfleet -o jsonpath="$1" 2>/dev/null; }

for _ in $(seq 1 36); do
  args=$(sts '{.spec.template.spec.containers[?(@.name=="prometheus")].args}')
  ready=$(sts '{.status.readyReplicas}')
  if [[ "$args" == *"--log.level=debug"* && "${ready:-0}" -ge 1 ]]; then break; fi
  sleep 5
done
[[ "$args" == *"--log.level=debug"* ]] || fail "the StatefulSet prometheus-starfleet has no --log.level=debug flag"
[[ "${ready:-0}" -ge 1 ]] || fail "the StatefulSet prometheus-starfleet has no ready pod"

owner=$(sts '{.metadata.ownerReferences[0].kind}')
[[ "$owner" == "Prometheus" ]] || fail "the StatefulSet is not owned by the Prometheus resource"

managers=$(sts '{.metadata.managedFields[*].manager}')
[[ "$managers" != *kubectl* ]] \
  || fail "the StatefulSet was changed with kubectl ($managers); the controller must write it"

echo "PASS: the controller wrote --log.level=debug into a ready StatefulSet"
