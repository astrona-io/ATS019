#!/usr/bin/env bash
# Check: the learner created the request first-probe in outpost, and the
# stored object carries the defaults.
set -uo pipefail
fail() { echo "FAIL: $1"; exit 1; }

kubectl -n outpost get probeenvironment first-probe >/dev/null 2>&1 \
  || fail "ProbeEnvironment first-probe does not exist in outpost"
field() { kubectl -n outpost get probeenvironment first-probe -o jsonpath="$1" 2>/dev/null; }

[ "$(field '{.spec.owner}')" = "drifter" ] || fail "first-probe spec.owner is not drifter"
[ "$(field '{.spec.tier}')" = "dev" ] || fail "first-probe spec.tier is '$(field '{.spec.tier}')', expected the default dev"
[ "$(field '{.spec.instances}')" = "2" ] || fail "first-probe spec.instances is '$(field '{.spec.instances}')', expected the default 2"

echo "PASS: first-probe is stored in outpost with owner drifter, tier dev and instances 2"
