#!/usr/bin/env bash
# run-tests.sh — Integration tests for bash scripts (run with API on :3000)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BASE_URL="${TEST_API_URL:-http://localhost:3000}"
PASS=0
FAIL=0

log() { echo "[run-tests] $*"; }
pass() { PASS=$((PASS + 1)); log "PASS: $1"; }
fail() { FAIL=$((FAIL + 1)); log "FAIL: $1"; }

wait_for_api() {
  for i in $(seq 1 30); do
    if curl -sf "${BASE_URL}/health" > /dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  return 1
}

if ! wait_for_api; then
  log "API not reachable at $BASE_URL — start with: npm start (examples/node-api) or docker compose up"
  exit 1
fi

chmod +x "$SCRIPT_DIR"/*.sh

# --- happy path ---
if "$SCRIPT_DIR/health-check.sh" "${BASE_URL}/health"; then
  pass "health-check.sh"
else
  fail "health-check.sh"
fi

for i in $(seq 1 5); do curl -sf "${BASE_URL}/api/example" > /dev/null; done

if "$SCRIPT_DIR/verify-metrics.sh" "${BASE_URL}/metrics"; then
  pass "verify-metrics.sh (direct)"
else
  fail "verify-metrics.sh (direct)"
fi

if GATE_SOAK_SECONDS=1 "$SCRIPT_DIR/production-gate.sh"; then
  pass "production-gate.sh (promote)"
else
  fail "production-gate.sh (promote)"
fi

# --- failure path: error rate ---
for i in $(seq 1 20); do
  curl -sf "${BASE_URL}/api/example/error" > /dev/null 2>&1 || true
done

if GATE_SOAK_SECONDS=1 "$SCRIPT_DIR/production-gate.sh"; then
  fail "production-gate.sh should fail after errors"
else
  pass "production-gate.sh (rollback on errors)"
fi

# --- deploy + rollback ---
DEPLOY_STATE_DIR="$ROOT/.deploy-state-test" DEPLOY_VERSION=v1-test "$SCRIPT_DIR/deploy-mock.sh"
DEPLOY_STATE_DIR="$ROOT/.deploy-state-test" DEPLOY_VERSION=v2-test "$SCRIPT_DIR/deploy-mock.sh"
if DEPLOY_STATE_DIR="$ROOT/.deploy-state-test" "$SCRIPT_DIR/rollback.sh" && [[ "$(cat "$ROOT/.deploy-state-test/current-version")" == "v1-test" ]]; then
  pass "rollback.sh"
else
  fail "rollback.sh"
fi
rm -rf "$ROOT/.deploy-state-test"

log "══════════════════════════════════"
log "Results: $PASS passed, $FAIL failed"
log "══════════════════════════════════"

[[ "$FAIL" -eq 0 ]]
