#!/usr/bin/env bash
# generate-traffic.sh — Generate sample requests for dashboards and gate testing
# Usage: ./scripts/generate-traffic.sh [options]
#
# Options:
#   --base-url URL   API base (default: http://localhost:3000)
#   --ok N           Successful /api/example requests (default: 20)
#   --errors N       /api/example/error requests (default: 0)
#   --slow N         /api/example/slow requests (default: 0)
#   --delay MS       Pause between requests in ms (default: 50)
#   -h, --help       Show help

set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:3000}"
OK_COUNT=20
ERROR_COUNT=0
SLOW_COUNT=0
DELAY_MS=50

usage() {
  sed -n '2,10p' "$0" | sed 's/^# \?//'
  exit 0
}

log() {
  echo "[generate-traffic] $(date -u +"%Y-%m-%dT%H:%M:%SZ") $*"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-url) BASE_URL="$2"; shift 2 ;;
    --ok) OK_COUNT="$2"; shift 2 ;;
    --errors) ERROR_COUNT="$2"; shift 2 ;;
    --slow) SLOW_COUNT="$2"; shift 2 ;;
    --delay) DELAY_MS="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

BASE_URL="${BASE_URL%/}"

if ! curl -sf "${BASE_URL}/health" > /dev/null 2>&1; then
  log "WARN: API not reachable at ${BASE_URL}/health — continuing anyway"
fi

sleep_ms() {
  if [[ "$DELAY_MS" -gt 0 ]]; then
    sleep "$(awk -v ms="$DELAY_MS" 'BEGIN { printf "%.3f", ms / 1000 }')"
  fi
}

hit() {
  local path="$1"
  local label="$2"
  if curl -sf "${BASE_URL}${path}" > /dev/null 2>&1; then
    log "  OK   ${label}"
  else
    log "  FAIL ${label} (expected for /error)"
  fi
  sleep_ms
}

log "Target: ${BASE_URL}"
log "Plan: ok=${OK_COUNT} errors=${ERROR_COUNT} slow=${SLOW_COUNT} delay=${DELAY_MS}ms"

if [[ "$OK_COUNT" -gt 0 ]]; then
  log "Sending ${OK_COUNT} successful requests..."
  for i in $(seq 1 "$OK_COUNT"); do
    hit "/api/example" "GET /api/example (${i}/${OK_COUNT})"
  done
fi

if [[ "$ERROR_COUNT" -gt 0 ]]; then
  log "Sending ${ERROR_COUNT} error requests..."
  for i in $(seq 1 "$ERROR_COUNT"); do
    hit "/api/example/error" "GET /api/example/error (${i}/${ERROR_COUNT})"
  done
fi

if [[ "$SLOW_COUNT" -gt 0 ]]; then
  log "Sending ${SLOW_COUNT} slow requests..."
  for i in $(seq 1 "$SLOW_COUNT"); do
    hit "/api/example/slow" "GET /api/example/slow (${i}/${SLOW_COUNT})"
  done
fi

log "Done. Open Grafana http://localhost:3001 or Prometheus http://localhost:9090"
