#!/usr/bin/env bash
# The AppProject is a boundary. The plausible wrong fixes are a wildcard kind,
# a cluster-scoped allow list, or a wide repository or namespace. All fail here.
set -uo pipefail
fail=0
REPO=http://gitea-http.gitea.svc:3000/starfleet/outpost-requests.git

value() { kubectl -n argocd get appproject outpost -o jsonpath="$1" 2>/dev/null; }

if ! kubectl -n argocd get appproject outpost >/dev/null 2>&1; then
  echo "FAIL: the AppProject outpost does not exist"; exit 1
fi

check_equal() {
  local label=$1 actual=$2 expected=$3
  if [ "$actual" = "$expected" ]; then
    echo "PASS: $label"
  else
    echo "FAIL: $label (found '$actual', expected '$expected')"; fail=1
  fi
}

check_equal "project allows only the TeamEnvironment kind" \
  "$(value '{.spec.namespaceResourceWhitelist[*].group}/{.spec.namespaceResourceWhitelist[*].kind}')" \
  "platform.starfleet.io/TeamEnvironment"
check_equal "project allows no cluster-scoped kind" \
  "$(value '{.spec.clusterResourceWhitelist}')" ""
check_equal "project allows only the outpost-requests repository" \
  "$(value '{.spec.sourceRepos[*]}')" "$REPO"
check_equal "project allows only the namespace outpost" \
  "$(value '{.spec.destinations[*].namespace}')" "outpost"
exit $fail
