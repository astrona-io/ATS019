#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work=$(mktemp -d)
restore() {
  kubectl delete rolebinding grader-cross-namespace -n starfleet --ignore-not-found >/dev/null
  kubectl apply -f "$DIR/solution/roles.yaml" >/dev/null
  rm -rf "$work"
}
trap restore EXIT
expect_rejected() {
  if bash "$DIR/validation/validate.sh" > "$work/result" 2>&1; then
    cat "$work/result"
    echo 'The grader accepted an excessive permission' >&2
    exit 1
  fi
  grep -q '^FAIL:' "$work/result" || { cat "$work/result"; exit 1; }
}
# A correct allowed request must not hide an out-of-namespace grant.
kubectl -n starfleet create rolebinding grader-cross-namespace --clusterrole=edit --user=platform-editor
expect_rejected
kubectl -n starfleet delete rolebinding grader-cross-namespace
# The viewer must not inherit writes through an aggregation label.
kubectl patch clusterrole teamenvironment-view --type=json -p '[{"op":"add","path":"/rules/0/verbs/-","value":"create"}]'
expect_rejected
restore
trap - EXIT
bash "$DIR/solution/apply.sh"
echo 'PASS: aggregation grader rejects namespace and viewer-write bypasses'
