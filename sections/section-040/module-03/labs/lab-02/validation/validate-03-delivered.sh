#!/usr/bin/env bash
# The request must travel through Git. A TeamEnvironment applied with kubectl
# has no Argo CD tracking annotation or label and fails the second check.
set -uo pipefail
fail=0

PASSWORD=$(kubectl -n gitea get secret gitea-platform -o jsonpath='{.data.password}' 2>/dev/null | base64 -d)
FILE=$(kubectl -n gitea exec deploy/gitea -- curl -sf -u "platform:${PASSWORD}" \
  http://localhost:3000/api/v1/repos/starfleet/outpost-requests/raw/requests/drifter.yaml 2>/dev/null)
if printf '%s' "$FILE" | grep -q 'kind: TeamEnvironment' && printf '%s' "$FILE" | grep -q 'name: drifter'; then
  echo "PASS: requests/drifter.yaml is committed in starfleet/outpost-requests"
else
  echo "FAIL: requests/drifter.yaml is not committed in starfleet/outpost-requests"; fail=1
fi

te() { kubectl -n outpost get teamenvironment drifter -o jsonpath="$1" 2>/dev/null; }

tracking=$(te '{.metadata.annotations.argocd\.argoproj\.io/tracking-id}')
instance=$(te '{.metadata.labels.app\.kubernetes\.io/instance}')
case "$tracking" in
  outpost-requests:*) echo "PASS: Argo CD created the TeamEnvironment (tracking-id annotation)" ;;
  *)
    if [ "$instance" = "outpost-requests" ]; then
      echo "PASS: Argo CD created the TeamEnvironment (instance label)"
    else
      echo "FAIL: the TeamEnvironment drifter is not managed by the Application outpost-requests"; fail=1
    fi ;;
esac

check_equal() {
  local label=$1 actual=$2 expected=$3
  if [ "$actual" = "$expected" ]; then
    echo "PASS: $label"
  else
    echo "FAIL: $label (found '$actual', expected '$expected')"; fail=1
  fi
}
check_equal "team is outpost" "$(te '{.spec.team}')" "outpost"
check_equal "size is small" "$(te '{.spec.size}')" "small"
check_equal "replicas is 1" "$(te '{.spec.replicas}')" "1"
check_equal "contact is drifter@outpost.starfleet.io" "$(te '{.spec.contact}')" "drifter@outpost.starfleet.io"
exit $fail
