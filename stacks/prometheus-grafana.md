# Prometheus + Grafana stack guide

This guide explains how the local observability stack works and how to adapt it for production.

## Local setup

```bash
docker compose up -d
```

| Service | URL | Purpose |
|---------|-----|---------|
| API | http://localhost:3000 | Sample app with `/metrics` |
| Prometheus | http://localhost:9090 | Metrics storage & queries |
| Grafana | http://localhost:3001 | Dashboards (admin / sensei) |
| Loki | http://localhost:3100 | Log aggregation (Grafana Explore) |
| Jaeger | http://localhost:16686 | Trace UI |

## How Prometheus scrapes our API

Config: [`stacks/prometheus/prometheus.yml`](prometheus/prometheus.yml)

```yaml
scrape_configs:
  - job_name: observability-sensei-api
    metrics_path: /metrics
    static_configs:
      - targets: ['api:3000']
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
```

Prometheus **pulls** metrics every 15 seconds. No agent needed in the app beyond exposing `/metrics`.

## Key queries for release validation

### Error rate (5m window)

```promql
sum(rate(http_request_errors_total[5m]))
/
sum(rate(http_requests_total[5m]))
```

### Request rate

```promql
sum(rate(http_requests_total[5m])) by (route)
```

### Latency p99

```promql
histogram_quantile(0.99,
  sum(rate(http_request_duration_seconds_bucket[5m])) by (le, route)
)
```

## Using Prometheus in CI/CD

Replace `verify-metrics.sh` parsing with direct PromQL queries:

```bash
RESULT=$(curl -s "http://prometheus:9090/api/v1/query" \
  --data-urlencode 'query=sum(rate(http_request_errors_total[5m]))/sum(rate(http_requests_total[5m]))')

ERROR_RATE=$(echo "$RESULT" | jq -r '.data.result[0].value[1]')
```

## Grafana dashboards

After `docker compose up`:

1. Open http://localhost:3001
2. Login: `admin` / `sensei`
3. Go to **Dashboards → observability-sensei → observability-sensei API**

The dashboard is auto-provisioned and includes:

| Panel | Query focus |
|-------|-------------|
| Request Rate | `rate(http_requests_total)` |
| Error Rate | errors / requests |
| Latency p99 | `http_request_duration_seconds` histogram |
| By route | RED metrics split by route |
| By status code | 2xx vs 5xx traffic |
| Node.js heap | `nodejs_heap_size_*` |

Refresh interval: **10s**. Default time range: **Last 15 minutes**.

### Manual setup (if not using compose provisioning)

1. **Connections → Data sources** → confirm Prometheus at `http://prometheus:9090`
2. **Dashboards → New → Import** → upload `stacks/grafana/dashboards/observability-sensei-api.json`

### Recommended panels (reference)

- Stat: current error rate
- Graph: request rate by route
- Heatmap: latency distribution
- Annotation: deploy events (add via API or CI)

## Production considerations

| Topic | Recommendation |
|-------|----------------|
| Retention | 15–30 days hot, long-term in object storage |
| HA | Run 2+ Prometheus replicas or use managed (AMP, Mimir) |
| Cardinality | Limit label values — avoid user IDs in labels |
| Security | `/metrics` on internal network only |
| Alerting | Prometheus → Alertmanager → PagerDuty/Slack |

## Exercise

1. Generate traffic to `/api/example` and `/api/example/error`
2. Run the error rate query in Prometheus UI
3. Correlate spike with deploy time in Grafana annotations
