#!/usr/bin/env bash
# Grader: the request is Synced and Ready.
set -uo pipefail

cond() {
  kubectl -n outpost get teamenvironment scout-env \
    -o jsonpath="{.status.conditions[?(@.type==\"$1\")].status}" 2>/dev/null
}

synced=$(cond Synced)
ready=$(cond Ready)
if [ "$synced" != "True" ] || [ "$ready" != "True" ]; then
  echo "FAIL: ready - Synced=${synced:-missing} Ready=${ready:-missing}, expected both True"
  exit 1
fi
echo "PASS: ready - scout-env is Synced and Ready"
