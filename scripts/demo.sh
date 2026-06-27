#!/usr/bin/env bash
# demo.sh — Quickstart: stack up, traffic, gate, print URLs
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

log() { echo "[demo] $*"; }

log "Starting observability stack..."
docker compose up -d --build

log "Waiting for API health..."
for i in $(seq 1 30); do
  if curl -sf http://localhost:3000/health | grep -q '"status":"ok"'; then
    break
  fi
  sleep 2
done

log "Generating sample traffic..."
for i in $(seq 1 15); do
  curl -sf http://localhost:3000/api/example > /dev/null
done

chmod +x examples/scripts/*.sh

log "Running Production Gate..."
GATE_SOAK_SECONDS=2 ./examples/scripts/production-gate.sh || true

echo ""
echo "════════════════════════════════════════════"
echo "  observability-sensei — stack ready"
echo "════════════════════════════════════════════"
echo "  API:        http://localhost:3000/health"
echo "  Metrics:    http://localhost:3000/metrics"
echo "  Prometheus: http://localhost:9090/targets"
echo "  Grafana:    http://localhost:3001  (admin / sensei)"
echo "  Loki:       Grafana Explore -> datasource Loki"
echo "  Jaeger:     http://localhost:16686"
echo "  Dashboard:  Grafana → observability-sensei → observability-sensei API"
echo "  Labs:       docs/labs/"
echo "  Docs (PT):  docs/pt/README.md"
echo "════════════════════════════════════════════"
