#!/usr/bin/env bash
# Test helper: waits until the cleanup Job is Complete.
set -euo pipefail

kubectl -n starfleet wait --for=condition=Complete job/probe-cleanup --timeout=180s
