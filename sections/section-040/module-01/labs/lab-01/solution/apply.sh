#!/usr/bin/env bash
# Reference solution for ats-019-lab-040-01. Applied only by `astrona test`.
# It stores the WorkflowTemplate. The next testing step submits the Workflow.
set -euo pipefail
cd "$(dirname "$0")"

kubectl apply -f solution.yaml
