#!/usr/bin/env bash
# The binding must name the group. A binding to the user outpost-dev would fail
# the first check, and a new team member would not get the rights.
set -uo pipefail
fail=0

answer=$(kubectl auth can-i create teamenvironments.platform.starfleet.io -n outpost --as new-teammate --as-group outpost-team 2>/dev/null)
if [ "$answer" = "yes" ]; then
  echo "PASS: another member of outpost-team can create teamenvironments"
else
  echo "FAIL: another member of outpost-team cannot create teamenvironments (bind the group, not the user)"; fail=1
fi

answer=$(kubectl auth can-i create teamenvironments.platform.starfleet.io -n outpost --as outpost-dev 2>/dev/null)
if [ "$answer" = "no" ]; then
  echo "PASS: outpost-dev without the group has no rights"
else
  echo "FAIL: outpost-dev has rights without the group (the binding names the user)"; fail=1
fi
exit $fail
