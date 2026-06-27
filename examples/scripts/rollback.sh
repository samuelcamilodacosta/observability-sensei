#!/usr/bin/env bash
# rollback.sh — Revert to previous known-good deployment version
# Usage: ./rollback.sh [optional-version-to-restore]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${DEPLOY_STATE_DIR:-$SCRIPT_DIR/../../.deploy-state}"
CURRENT_FILE="$STATE_DIR/current-version"
PREVIOUS_FILE="$STATE_DIR/previous-version"
TARGET_VERSION="${1:-}"

log() {
  echo "[rollback] $(date -u +"%Y-%m-%dT%H:%M:%SZ") $*"
}

ensure_state_dir() {
  mkdir -p "$STATE_DIR"
}

get_rollback_target() {
  if [[ -n "$TARGET_VERSION" ]]; then
    echo "$TARGET_VERSION"
    return
  fi

  if [[ -f "$PREVIOUS_FILE" ]]; then
    cat "$PREVIOUS_FILE"
    return
  fi

  echo "unknown"
}

main() {
  ensure_state_dir

  local current previous restore

  current=$(cat "$CURRENT_FILE" 2>/dev/null || echo "none")
  restore=$(get_rollback_target)
  previous=$(cat "$PREVIOUS_FILE" 2>/dev/null || echo "none")

  log "═══════════════════════════════════════════"
  log "  ROLLBACK initiated"
  log "═══════════════════════════════════════════"
  log "Current (failed) version: $current"
  log "Rolling back to: $restore"
  log "Previous in history: $previous"

  if [[ "$restore" == "unknown" || "$restore" == "none" ]]; then
    log "FAIL: no previous version to restore"
    log "Hint: run deploy-mock.sh at least twice to build version history"
    exit 1
  fi

  # In production: kubectl rollout undo / redeploy image tag / flip LB
  log "Executing rollback (mock)..."
  sleep 2

  echo "$current" > "$STATE_DIR/failed-version"
  echo "$restore" > "$CURRENT_FILE"

  if [[ -f "$SCRIPT_DIR/health-check.sh" ]]; then
    log "Verifying rolled-back deployment health..."
    SERVICE_URL="${GATE_HEALTH_URL:-http://localhost:3000/health}"
    if "$SCRIPT_DIR/health-check.sh" "$SERVICE_URL" 5 2; then
      log "✓ Post-rollback health check passed"
    else
      log "WARN: post-rollback health check failed — manual intervention required"
    fi
  fi

  log "✅ Rollback complete — active version: $restore"
  log "═══════════════════════════════════════════"
}

main "$@"
