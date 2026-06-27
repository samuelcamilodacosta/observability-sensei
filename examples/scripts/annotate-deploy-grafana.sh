#!/usr/bin/env bash
# annotate-deploy-grafana.sh — Post deploy annotation in Grafana (optional)
# Usage: DEPLOY_VERSION=abc123 ./annotate-deploy-grafana.sh
set -euo pipefail

GRAFANA_URL="${GRAFANA_URL:-http://localhost:3001}"
GRAFANA_USER="${GRAFANA_USER:-admin}"
GRAFANA_PASSWORD="${GRAFANA_PASSWORD:-sensei}"
DEPLOY_VERSION="${DEPLOY_VERSION:-unknown}"
DASHBOARD_UID="${GRAFANA_DASHBOARD_UID:-observability-sensei-api}"

payload=$(cat <<EOF
{
  "dashboardUID": "$DASHBOARD_UID",
  "time": $(date +%s000),
  "tags": ["deploy", "observability-sensei"],
  "text": "Deploy $DEPLOY_VERSION"
}
EOF
)

curl -sf -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
  -H "Content-Type: application/json" \
  -X POST "${GRAFANA_URL}/api/annotations" \
  -d "$payload" && echo "[annotate] Deploy annotation created: $DEPLOY_VERSION"
