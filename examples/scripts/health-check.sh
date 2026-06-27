#!/usr/bin/env bash
# health-check.sh — Post-deploy liveness/readiness validation
# Usage: ./health-check.sh [URL] [max_retries] [retry_interval_sec]

set -euo pipefail

HEALTH_URL="${1:-${GATE_HEALTH_URL:-http://localhost:3000/health}}"
MAX_RETRIES="${2:-${HEALTH_CHECK_RETRIES:-10}}"
RETRY_INTERVAL="${3:-${HEALTH_CHECK_INTERVAL:-3}}"
TIMEOUT_SEC="${HEALTH_CHECK_TIMEOUT:-5}"

log() {
  echo "[health-check] $(date -u +"%Y-%m-%dT%H:%M:%SZ") $*"
}

check_health() {
  local response
  local http_code

  response=$(curl -sf --max-time "$TIMEOUT_SEC" -w "\n%{http_code}" "$HEALTH_URL" 2>/dev/null) || return 1
  http_code=$(echo "$response" | tail -n1)
  body=$(echo "$response" | sed '$d')

  if [[ "$http_code" != "200" ]]; then
    log "FAIL: HTTP $http_code from $HEALTH_URL"
    return 1
  fi

  if ! echo "$body" | grep -q '"status"[[:space:]]*:[[:space:]]*"ok"'; then
    log "FAIL: body does not contain status ok"
    log "Response: $body"
    return 1
  fi

  log "OK: health check passed (HTTP 200, status=ok)"
  echo "$body"
  return 0
}

main() {
  log "Starting health check: $HEALTH_URL (retries=$MAX_RETRIES, interval=${RETRY_INTERVAL}s)"

  for attempt in $(seq 1 "$MAX_RETRIES"); do
    log "Attempt $attempt/$MAX_RETRIES"

    if check_health; then
      exit 0
    fi

    if [[ "$attempt" -lt "$MAX_RETRIES" ]]; then
      log "Retrying in ${RETRY_INTERVAL}s..."
      sleep "$RETRY_INTERVAL"
    fi
  done

  log "FAIL: health check exhausted all retries"
  exit 1
}

main "$@"
