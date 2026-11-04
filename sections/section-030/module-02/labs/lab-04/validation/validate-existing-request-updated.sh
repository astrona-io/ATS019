#!/usr/bin/env bash
# A newly owned Service and a newer revision prove adoption, not just preservation.
source "$(dirname "$0")/common.sh"
require_equal "$(xr_field outpost-scout '.metadata.uid')" "$(saved xr-uid)" 'the original composite resource was recreated'
require_equal "$(field -n outpost get statefulset outpost-scout -o 'jsonpath={.metadata.uid}')" "$(saved sts-uid)" 'the original StatefulSet was recreated'
require_equal "$(field -n outpost get service outpost-scout-pods -o 'jsonpath={.metadata.uid}')" "$(saved head-uid)" 'the original governing Service was recreated'
require_equal "$(xr_field outpost-scout '.spec.crossplane.compositionRef.name')" scout-stateful 'keep the original Composition reference'
require_equal "$(xr_field outpost-scout '.spec.crossplane.compositionUpdatePolicy')" Automatic 'keep Automatic updates'
REVISION="$(xr_field outpost-scout '.spec.crossplane.compositionRevisionRef.name')"
[ -n "$REVISION" ] && [ "$REVISION" != "$(saved revision)" ] || fail 'the original request has not adopted a new revision'
require_equal "$(field get compositionrevision "$REVISION" -o 'jsonpath={.spec.pipeline[0].input.resources}')" "$(comp_field '.spec.pipeline[0].input.resources')" 'the original request must use the updated resource templates'
check_ready outpost-scout
check_owned_service outpost-scout
echo 'PASS: existing-request-updated'
