#!/usr/bin/env bash
# Grader: the TeamEnvironment scout-env is gone. An object that is only
# marked for deletion (it still has a deletionTimestamp) does not count.
set -uo pipefail

found=$(kubectl -n outpost get teamenvironment scout-env --ignore-not-found -o name 2>&1)
if [ -n "$found" ]; then
  echo "FAIL: request-gone - ${found} still exists in the namespace outpost"
  exit 1
fi
echo "PASS: request-gone - the TeamEnvironment scout-env is gone"
