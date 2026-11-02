#!/usr/bin/env bash
# The tenant's extra scrape job must exist and must still be wired in. Removing
# additionalScrapeConfigs from the Prometheus resource does not pass.
set -u

fail() { echo "FAIL: $*"; exit 1; }
prom() { kubectl -n outpost get prometheus tenant -o jsonpath="$1" 2>/dev/null; }

[[ "$(prom '{.spec.additionalScrapeConfigs.name}')" == "tenant-scrape" && "$(prom '{.spec.additionalScrapeConfigs.key}')" == "jobs.yaml" ]] \
  || fail "spec.additionalScrapeConfigs of the Prometheus resource tenant was changed; keep it and create the Secret"

jobs=$(kubectl -n outpost get secret tenant-scrape -o go-template='{{index .data "jobs.yaml" | base64decode}}' 2>/dev/null) \
  || fail "the Secret tenant-scrape with the key jobs.yaml does not exist in outpost"

[[ "$jobs" == *"job_name: scout-extra"* ]] \
  || fail "jobs.yaml has no scrape job with job_name: scout-extra"
[[ "$jobs" == *"scout.outpost.svc:9898"* ]] \
  || fail "the scout-extra job does not target scout.outpost.svc:9898"

echo "PASS: the Secret tenant-scrape holds the scout-extra job and the Prometheus resource still uses it"
