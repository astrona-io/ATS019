#!/usr/bin/env bash
# Reference solution: delete the request with orphan cascading, so the
# composed Object resources, the Deployment and the Service stay.
set -euo pipefail

kubectl -n outpost delete teamenvironment scout-env --cascade=orphan --wait=true --timeout=180s
