#!/usr/bin/env bash
# canary-mock.sh — Simulated canary deploy: small traffic slice → gate → full promote
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CANARY_REQUESTS="${CANARY_REQUESTS:-5}"
STABLE_URL="${CANARY_STABLE_URL:-http://localhost:3000}"
CANARY_PERCENT="${CANARY_PERCENT:-10}"

log() { echo "[canary] $(date -u +"%Y-%m-%dT%H:%M:%SZ") $*"; }

log "Canary deploy mock — ${CANARY_PERCENT}% traffic slice"
log "Deploying canary version (mock)..."
DEPLOY_VERSION="canary-$(date +%s)" "$SCRIPT_DIR/deploy-mock.sh"

log "Routing ~${CANARY_REQUESTS} requests to canary paths..."
for i in $(seq 1 "$CANARY_REQUESTS"); do
  curl -sf "${STABLE_URL}/api/example" > /dev/null
done

log "Running Production Gate on canary slice..."
export GATE_HEALTH_URL="${STABLE_URL}/health"
export GATE_METRICS_URL="${STABLE_URL}/metrics"
export GATE_SOAK_SECONDS="${GATE_SOAK_SECONDS:-2}"

if "$SCRIPT_DIR/production-gate.sh"; then
  log "✅ Canary passed — promoting to 100% traffic (mock)"
  DEPLOY_VERSION="promoted-$(date +%s)" "$SCRIPT_DIR/deploy-mock.sh"
  exit 0
else
  log "❌ Canary failed — rolling back, stable traffic unchanged"
  "$SCRIPT_DIR/rollback.sh"
  exit 1
fi
