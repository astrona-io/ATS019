#!/usr/bin/env bash
# Grader: the scout Deployment follows the request. Replicas come from
# spec.replicas and the team label from spec.team, both through the Composition.
set -uo pipefail

dep() { kubectl -n outpost get deployment scout -o jsonpath="$1" 2>/dev/null; }

replicas=$(dep '{.spec.replicas}')
available=$(dep '{.status.availableReplicas}')
team=$(dep '{.spec.template.metadata.labels.team}')
if [ -z "$replicas" ]; then
  echo "FAIL: workload - no Deployment named scout in the namespace outpost"
  exit 1
fi
if [ "$replicas" != "2" ] || [ "$available" != "2" ] || [ "$team" != "outpost" ]; then
  echo "FAIL: workload - expected replicas=2 available=2 team label=outpost, got replicas=${replicas} available=${available:-0} team=${team:-none}"
  exit 1
fi
echo "PASS: workload - the scout Deployment runs 2 replicas with the team label outpost"
