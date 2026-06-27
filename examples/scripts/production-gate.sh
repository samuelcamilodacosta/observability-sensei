#!/usr/bin/env bash
# production-gate.sh — Decide: promote release OR trigger rollback
# Evaluates health, error rate, and latency threshold (simulated from metrics histogram)
# Usage: ./production-gate.sh
# Exit 0 = promote | Exit 1 = rollback

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HEALTH_URL="${GATE_HEALTH_URL:-http://localhost:3000/health}"
METRICS_URL="${GATE_METRICS_URL:-http://localhost:3000/metrics}"
MAX_ERROR_RATE="${GATE_MAX_ERROR_RATE:-0.05}"
MAX_LATENCY_MS="${GATE_MAX_LATENCY_MS:-500}"
SOAK_SECONDS="${GATE_SOAK_SECONDS:-5}"

log() {
  echo "[production-gate] $(date -u +"%Y-%m-%dT%H:%M:%SZ") $*"
}

simulate_latency_check() {
  local metrics_body max_bucket_latency sum count bucket le ms

  metrics_body=$(curl -sf --max-time 5 "$METRICS_URL") || return 1

  max_bucket_latency=0
  while IFS= read -r line; do
    [[ "$line" =~ ^http_simulated_latency_ms_bucket ]] || continue
    if [[ "$line" =~ le=\"([0-9.]+)\" ]]; then
      le="${BASH_REMATCH[1]}"
      ms=$(echo "$line" | awk '{print $NF}')
      if awk -v ms="$ms" -v le="$le" -v max="$max_bucket_latency" 'BEGIN { exit !(ms > 0 && le > max) }'; then
        max_bucket_latency="$le"
      fi
    fi
  done <<< "$metrics_body"

  # Estimate p99 from histogram: use highest non-zero bucket upper bound as proxy
  local estimated_p99
  estimated_p99=$(awk -v b="$max_bucket_latency" 'BEGIN { if (b == 0) print 50; else print b * 1000 }')

  # If slow endpoint was hit, buckets include 600+ values
  local slow_hits
  slow_hits=$(echo "$metrics_body" | grep 'http_simulated_latency_ms_count' | awk '{sum+=$NF} END {print sum+0}')

  if [[ "$slow_hits" -gt 0 ]]; then
    estimated_p99=$(echo "$metrics_body" | grep 'http_simulated_latency_ms_bucket' | awk '{print $NF}' | sort -n | tail -1)
    estimated_p99=${estimated_p99:-50}
  fi

  log "Latency check: estimated p99 ≈ ${estimated_p99}ms (threshold: ${MAX_LATENCY_MS}ms)"

  if awk -v lat="$estimated_p99" -v max="$MAX_LATENCY_MS" 'BEGIN { exit !(lat <= max) }'; then
    return 0
  fi

  log "FAIL: latency threshold exceeded"
  return 1
}

main() {
  log "═══════════════════════════════════════════"
  log "  PRODUCTION GATE — release validation"
  log "═══════════════════════════════════════════"
  log "Soak period: ${SOAK_SECONDS}s before checks"
  sleep "$SOAK_SECONDS"

  local failed=0

  log "── Step 1/3: Health check ──"
  if "$SCRIPT_DIR/health-check.sh" "$HEALTH_URL"; then
    log "✓ Health check passed"
  else
    log "✗ Health check failed"
    failed=1
  fi

  log "── Step 2/3: Error rate validation ──"
  if GATE_MAX_ERROR_RATE="$MAX_ERROR_RATE" "$SCRIPT_DIR/verify-metrics.sh" "$METRICS_URL"; then
    log "✓ Metrics validation passed"
  else
    log "✗ Metrics validation failed"
    failed=1
  fi

  log "── Step 3/3: Latency threshold ──"
  if simulate_latency_check; then
    log "✓ Latency check passed"
  else
    log "✗ Latency check failed"
    failed=1
  fi

  log "═══════════════════════════════════════════"
  if [[ "$failed" -eq 0 ]]; then
    log "✅ PRODUCTION GATE: PROMOTE — release validated"
    exit 0
  else
    log "❌ PRODUCTION GATE: ROLLBACK — one or more checks failed"
    exit 1
  fi
}

main "$@"
