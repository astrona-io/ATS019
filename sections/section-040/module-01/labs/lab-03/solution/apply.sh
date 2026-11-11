#!/usr/bin/env bash
# Reference solution for ats-019-lab-040-01-03. Applied only by `astrona test`.
# It stores the Role, the RoleBinding and the WorkflowTemplate. The next
# testing step runs the template and plays the controller.
set -euo pipefail
cd "$(dirname "$0")"

kubectl apply -f solution.yaml
