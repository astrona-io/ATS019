#!/usr/bin/env bash
# Reference solution: applies the EventBus, the webhook EventSource, the Role
# and RoleBinding for the Sensor, and the Sensor. Used only by `astrona test`.
set -euo pipefail
cd "$(dirname "$0")"
kubectl apply -f solution.yaml
bash wait-ready.sh
