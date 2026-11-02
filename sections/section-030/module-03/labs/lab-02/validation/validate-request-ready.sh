#!/usr/bin/env bash
# Grader: the original request is untouched (fix the Composition, not the
# request) and it is now Synced and Ready.
set -uo pipefail

jp() { kubectl -n outpost get teamenvironment scout-env -o jsonpath="$1" 2>/dev/null; }

if [ -z "$(jp '{.metadata.name}')" ]; then
  echo "FAIL: request-ready - no TeamEnvironment named scout-env in the namespace outpost"
  exit 1
fi
team=$(jp '{.spec.team}')
replicas=$(jp '{.spec.replicas}')
composition=$(jp '{.spec.crossplane.compositionRef.name}')
if [ "$team" != "outpost" ] || [ "$replicas" != "2" ] || [ "$composition" != "teamenvironment" ]; then
  echo "FAIL: request-ready - the request was changed: team=${team} replicas=${replicas} composition=${composition}, expected outpost, 2, teamenvironment"
  exit 1
fi
synced=$(jp '{.status.conditions[?(@.type=="Synced")].status}')
ready=$(jp '{.status.conditions[?(@.type=="Ready")].status}')
if [ "$synced" != "True" ] || [ "$ready" != "True" ]; then
  echo "FAIL: request-ready - Synced=${synced:-missing} Ready=${ready:-missing}, expected both True"
  exit 1
fi
echo "PASS: request-ready - scout-env is unchanged, Synced and Ready"
