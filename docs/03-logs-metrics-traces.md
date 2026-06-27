# Logs, Metrics, and Traces

This chapter maps each pillar to code in `examples/node-api` and shows how they work together during a deploy.

## Structured logging

**Bad:**

```
User logged in successfully
```

**Good:**

```json
{
  "level": "info",
  "msg": "request completed",
  "requestId": "abc-123",
  "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
  "method": "GET",
  "path": "/api/example",
  "statusCode": 200,
  "durationMs": 12,
  "service": "observability-sensei-api",
  "version": "1.0.0"
}
```

### Why structure matters

- Log aggregators (Loki, CloudWatch, Datadog) index fields
- You can filter `statusCode >= 500 AND version = "abc1234"`
- Pipelines can grep JSON reliably

Implementation: [`examples/node-api/src/logger.ts`](../examples/node-api/src/logger.ts)

### Logging rules for production

1. Log to **stdout** — let the platform collect
2. Use **log levels** correctly (don't log errors as info)
3. Never log secrets, tokens, or PII
4. Include **requestId** and **traceId** on every request log

## Metrics (Prometheus style)

Metrics are numbers that change over time. Prometheus **pulls** them from `/metrics` on an interval.

### Metric types we use

| Type | Example | Use |
|------|---------|-----|
| Counter | `http_requests_total` | Only goes up — request count |
| Histogram | `http_request_duration_seconds` | Latency distribution |
| Gauge | `active_connections` | Value that goes up and down |

Our API exposes:

```
http_requests_total{method="GET",route="/api/example",status_code="200"} 42
http_request_errors_total{route="/api/example"} 3
```

Implementation: [`examples/node-api/src/metrics.ts`](../examples/node-api/src/metrics.ts)

### Pipeline integration

After deploy, `verify-metrics.sh`:

1. Scrapes `/metrics`
2. Parses error counters
3. Fails if error rate exceeds threshold

This is a simplified version of what you'd do with Prometheus queries in CI:

```promql
rate(http_request_errors_total[5m]) / rate(http_requests_total[5m]) < 0.05
```

See [`stacks/prometheus-grafana.md`](../stacks/prometheus-grafana.md) for the full stack.

## Distributed tracing (OpenTelemetry)

Traces show the path of a request through your system.

```
[HTTP GET /api/example]
    │
    ├── span: express.middleware
    ├── span: example.handler
    └── span: simulate-db-call (8ms)
```

### Why traces in CI/CD?

- Prove new code paths are exercised post-deploy
- Compare trace error rates between versions
- Debug "works in staging, slow in prod"

Implementation: [`examples/node-api/src/telemetry.ts`](../examples/node-api/src/telemetry.ts)

We export traces to the console in dev. In production you'd use OTLP to Jaeger, Tempo, or a vendor backend.

See [`stacks/opentelemetry.md`](../stacks/opentelemetry.md).

## Correlation: the superpower

When logs, metrics, and traces share IDs:

```
Alert: error rate high
  → Metrics: spike on version v2.3.1
  → Logs: filter traceId from sample error log
  → Trace: see downstream call timing out
```

Always propagate:

- `X-Request-Id` header
- W3C `traceparent` header (OpenTelemetry handles this)

## Exercise

1. `docker compose up -d`
2. Generate traffic: `for i in $(seq 1 20); do curl -s http://localhost:3000/api/example > /dev/null; done`
3. Open Prometheus at http://localhost:9090 — query `http_requests_total`
4. Trigger errors: `curl http://localhost:3000/api/example/error`
5. Run `./examples/scripts/verify-metrics.sh http://localhost:3000/metrics`

Next: [Release observability](./04-release-observability.md)
