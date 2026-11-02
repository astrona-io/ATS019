#!/usr/bin/env bash
# Grader: a TeamEnvironment named scout-env exists in outpost with the requested values.
set -uo pipefail

jp() { kubectl -n outpost get teamenvironment scout-env -o jsonpath="$1" 2>/dev/null; }

team=$(jp '{.spec.team}')
size=$(jp '{.spec.size}')
replicas=$(jp '{.spec.replicas}')
if [ -z "$team" ]; then
  echo "FAIL: request - no TeamEnvironment named scout-env in the namespace outpost"
  exit 1
fi
if [ "$team" != "outpost" ] || [ "$size" != "medium" ] || [ "$replicas" != "2" ]; then
  echo "FAIL: request - expected team=outpost size=medium replicas=2, got team=${team} size=${size} replicas=${replicas}"
  exit 1
fi
echo "PASS: request - scout-env asks for team outpost, size medium, replicas 2"
