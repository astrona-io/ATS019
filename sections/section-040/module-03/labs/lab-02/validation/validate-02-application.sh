#!/usr/bin/env bash
# The Application must stay in the outpost project. Moving it to `default`
# makes it work and removes the boundary, so that fix fails here.
set -uo pipefail
fail=0
REPO=http://gitea-http.gitea.svc:3000/starfleet/outpost-requests.git

value() { kubectl -n argocd get application outpost-requests -o jsonpath="$1" 2>/dev/null; }

check_equal() {
  local label=$1 actual=$2 expected=$3
  if [ "$actual" = "$expected" ]; then
    echo "PASS: $label"
  else
    echo "FAIL: $label (found '$actual', expected '$expected')"; fail=1
  fi
}

check_equal "Application is in the outpost project" "$(value '{.spec.project}')" "outpost"
check_equal "Application reads the outpost-requests repository" "$(value '{.spec.source.repoURL}')" "$REPO"
check_equal "Application reads the requests folder" "$(value '{.spec.source.path}')" "requests"
check_equal "Application writes to the namespace outpost" "$(value '{.spec.destination.namespace}')" "outpost"
check_equal "automated sync has prune enabled" "$(value '{.spec.syncPolicy.automated.prune}')" "true"
check_equal "automated sync has selfHeal enabled" "$(value '{.spec.syncPolicy.automated.selfHeal}')" "true"
exit $fail
