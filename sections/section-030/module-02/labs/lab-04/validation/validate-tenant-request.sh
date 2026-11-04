#!/usr/bin/env bash
# The untouched state has no outpost-probe request.
source "$(dirname "$0")/common.sh"
require_equal "$(xr_field outpost-probe '.spec.team')" probe 'outpost-probe must set spec.team to probe'
require_equal "$(xr_field outpost-probe '.spec.crossplane.compositionRef.name')" scout-stateful 'outpost-probe must use scout-stateful'
require_equal "$(xr_field outpost-probe '.spec.crossplane.compositionUpdatePolicy')" Automatic 'outpost-probe must use Automatic updates'
check_ready outpost-probe
require_equal "$(field -n outpost get statefulset outpost-probe -o 'jsonpath={.metadata.ownerReferences[?(@.controller==true)].uid}')" "$(xr_field outpost-probe '.metadata.uid')" 'the new request must own its native StatefulSet'
echo 'PASS: tenant-request'
