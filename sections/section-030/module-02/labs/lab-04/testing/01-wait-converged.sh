#!/usr/bin/env bash
set -euo pipefail
# Ready may still describe the old revision; wait for both new Services too.
for name in outpost-scout outpost-probe; do
  for attempt in $(seq 1 90); do
    kubectl -n outpost get service "$name" >/dev/null 2>&1 && break
    sleep 2
  done
  kubectl -n outpost get service "$name"
  kubectl -n outpost wait "teamenvironment/$name" --for=condition=Synced --timeout=300s
  kubectl -n outpost wait "teamenvironment/$name" --for=condition=Ready --timeout=300s
  kubectl -n outpost rollout status "statefulset/$name" --timeout=240s
done
