#!/usr/bin/env bash
# deploy-mock.sh — Simulates a deployment and tracks version state for rollback demos
# Usage: DEPLOY_VERSION=abc123 ./deploy-mock.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${DEPLOY_STATE_DIR:-$SCRIPT_DIR/../../.deploy-state}"
VERSION="${DEPLOY_VERSION:-${GITHUB_SHA:-$(git rev-parse --short HEAD 2>/dev/null || echo "local-$(date +%s)")}}"

log() {
  echo "[deploy] $(date -u +"%Y-%m-%dT%H:%M:%SZ") $*"
}

main() {
  mkdir -p "$STATE_DIR"

  if [[ -f "$STATE_DIR/current-version" ]]; then
    cp "$STATE_DIR/current-version" "$STATE_DIR/previous-version"
  fi

  log "Deploying version: $VERSION"
  log "Building container image (mock)..."
  sleep 1
  log "Pushing to registry (mock)..."
  sleep 1
  log "Updating running service (mock)..."
  sleep 2

  echo "$VERSION" > "$STATE_DIR/current-version"
  echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "$STATE_DIR/deployed-at"

  log "✅ Deploy complete — version $VERSION is live"
}

main "$@"
