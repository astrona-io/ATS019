#!/usr/bin/env bash
# Reference solution for ats-019-lab-040-01-02. Applied only by `astrona test`.
# The Role gets the Services rule and the RoleBinding names the right namespace
# for the ServiceAccount.
set -euo pipefail
cd "$(dirname "$0")"

kubectl apply -f solution.yaml
