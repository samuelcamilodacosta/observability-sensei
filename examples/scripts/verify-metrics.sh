#!/usr/bin/env bash
# verify-metrics.sh — Post-deploy metrics validation
# Usage: ./verify-metrics.sh [METRICS_URL]
# Modes: VERIFY_MODE=direct (default) | prometheus

set -euo pipefail

METRICS_URL="${1:-${GATE_METRICS_URL:-http://localhost:3000/metrics}}"
MAX_ERROR_RATE="${GATE_MAX_ERROR_RATE:-0.05}"
MIN_REQUESTS="${GATE_MIN_REQUESTS:-1}"
TIMEOUT_SEC="${METRICS_CHECK_TIMEOUT:-5}"
VERIFY_MODE="${VERIFY_MODE:-direct}"
PROMETHEUS_URL="${PROMETHEUS_URL:-http://localhost:9090}"

log() {
  echo "[verify-metrics] $(date -u +"%Y-%m-%dT%H:%M:%SZ") $*"
}

parse_counter_total() {
  local metric_name="$1"
  local metrics_body="$2"
  local sum=0
  local line value

  while IFS= read -r line; do
    [[ "$line" =~ ^# ]] && continue
    [[ "$line" =~ ^${metric_name}\{ ]] || [[ "$line" =~ ^${metric_name}[[:space:]] ]] || continue
    value=$(echo "$line" | awk '{print $NF}')
    if [[ "$value" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
      sum=$(awk -v a="$sum" -v b="$value" 'BEGIN { printf "%.6f", a + b }')
    fi
  done <<< "$metrics_body"

  echo "$sum"
}

verify_via_prometheus() {
  log "Mode: prometheus ($PROMETHEUS_URL)"
  local query='sum(rate(http_request_errors_total[5m])) / sum(rate(http_requests_total[5m]))'
  local response error_rate

  response=$(curl -sf --max-time "$TIMEOUT_SEC" \
    -G "${PROMETHEUS_URL}/api/v1/query" \
    --data-urlencode "query=${query}") || {
    log "FAIL: Prometheus query failed"
    exit 1
  }

  if command -v jq >/dev/null 2>&1; then
    error_rate=$(echo "$response" | jq -r '.data.result[0].value[1] // "0"')
  else
    error_rate=$(echo "$response" | grep -o '"value":\[[^]]*\]' | tail -1 | grep -o '[0-9.]*$' || echo "0")
  fi

  log "Prometheus error rate (5m): $error_rate"

  if awk -v rate="$error_rate" -v max="$MAX_ERROR_RATE" 'BEGIN { exit !(rate <= max) }'; then
    log "OK: error rate within threshold"
    exit 0
  else
    log "FAIL: error rate $error_rate exceeds max $MAX_ERROR_RATE"
    exit 1
  fi
}

verify_direct() {
  log "Mode: direct scrape ($METRICS_URL)"
  log "Max error rate threshold: $MAX_ERROR_RATE"

  local metrics_body total_requests total_errors error_rate

  metrics_body=$(curl -sf --max-time "$TIMEOUT_SEC" "$METRICS_URL") || {
    log "FAIL: could not fetch metrics endpoint"
    exit 1
  }

  if ! echo "$metrics_body" | grep -q 'http_requests_total'; then
    log "FAIL: http_requests_total metric not found"
    exit 1
  fi

  total_requests=$(parse_counter_total "http_requests_total" "$metrics_body")
  total_errors=$(parse_counter_total "http_request_errors_total" "$metrics_body")

  log "Total requests: $total_requests"
  log "Total errors: $total_errors"

  if ! awk -v req="$total_requests" -v min="$MIN_REQUESTS" 'BEGIN { exit !(req >= min) }'; then
    log "WARN: only $total_requests requests — generating probe traffic"
    curl -sf "${METRICS_URL%/metrics}/api/example" > /dev/null || true
    sleep 1
    metrics_body=$(curl -sf --max-time "$TIMEOUT_SEC" "$METRICS_URL")
    total_requests=$(parse_counter_total "http_requests_total" "$metrics_body")
    total_errors=$(parse_counter_total "http_request_errors_total" "$metrics_body")
    log "After probe — requests: $total_requests, errors: $total_errors"
  fi

  if ! awk -v req="$total_requests" -v min="$MIN_REQUESTS" 'BEGIN { exit !(req >= min) }'; then
    log "FAIL: insufficient request volume for validation"
    exit 1
  fi

  error_rate=$(awk -v e="$total_errors" -v r="$total_requests" 'BEGIN { if (r == 0) print 0; else print e / r }')
  log "Computed error rate: $error_rate"

  if awk -v rate="$error_rate" -v max="$MAX_ERROR_RATE" 'BEGIN { exit !(rate <= max) }'; then
    log "OK: error rate within threshold"
    exit 0
  else
    log "FAIL: error rate $error_rate exceeds max $MAX_ERROR_RATE"
    exit 1
  fi
}

main() {
  if [[ "$VERIFY_MODE" == "prometheus" ]]; then
    verify_via_prometheus
  else
    verify_direct
  fi
}

main "$@"
