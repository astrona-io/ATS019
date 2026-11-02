#!/usr/bin/env bash
# Starts Gitea (plumbing), creates the user `platform`, the organisation
# `starfleet` and the public repository `starfleet/outpost-requests` with an
# empty `requests/` folder (a placeholder file keeps the folder in Git).
# The repository is public, so Argo CD reads it without credentials.
set -euo pipefail
cd "$(dirname "$0")/.."

PASSWORD=platform-secret-19
API=http://localhost:3000/api/v1

kubectl apply -f manifests/gitea.yaml >/dev/null
kubectl -n gitea rollout status deployment/gitea --timeout=300s

kubectl -n gitea exec deploy/gitea -- gitea admin user create \
  --admin --username platform --password "$PASSWORD" \
  --email platform@starfleet.io --must-change-password=false >/dev/null

gitea_api() {
  kubectl -n gitea exec deploy/gitea -- curl -sf -u "platform:${PASSWORD}" \
    -H 'Content-Type: application/json' "$@" >/dev/null
}

gitea_api -X POST "$API/orgs" -d '{"username":"starfleet","visibility":"public"}'
gitea_api -X POST "$API/orgs/starfleet/repos" \
  -d '{"name":"outpost-requests","private":false,"auto_init":true,"default_branch":"main"}'
# base64 of "keep\n"
gitea_api -X POST "$API/repos/starfleet/outpost-requests/contents/requests/.gitkeep" \
  -d '{"content":"a2VlcAo=","message":"Create the requests folder"}'
