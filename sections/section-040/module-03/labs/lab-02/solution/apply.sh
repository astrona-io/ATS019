#!/usr/bin/env bash
# Reference end state. Applied only by `astrona test`. Fixes the AppProject
# and the Application, then commits requests/drifter.yaml to Gitea through its
# API (the same effect as git add, commit and push).
set -euo pipefail
cd "$(dirname "$0")"

kubectl apply -f solution.yaml

REQUEST='apiVersion: platform.starfleet.io/v1alpha1
kind: TeamEnvironment
metadata:
  name: drifter
  namespace: outpost
spec:
  team: outpost
  size: small
  replicas: 1
  contact: drifter@outpost.starfleet.io
'
ENCODED=$(printf '%s' "$REQUEST" | base64 | tr -d '\n')
PASSWORD=$(kubectl -n gitea get secret gitea-platform -o jsonpath='{.data.password}' | base64 -d)

kubectl -n gitea exec deploy/gitea -- curl -sf -u "platform:${PASSWORD}" \
  -H 'Content-Type: application/json' -X POST \
  http://localhost:3000/api/v1/repos/starfleet/outpost-requests/contents/requests/drifter.yaml \
  -d "{\"content\":\"${ENCODED}\",\"message\":\"Request environment for drifter\"}" >/dev/null
kubectl -n argocd annotate application outpost-requests \
  argocd.argoproj.io/refresh=hard --overwrite
