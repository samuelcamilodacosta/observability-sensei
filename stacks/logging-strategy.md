# Logging strategy

Structured logging is the foundation of production debugging. This guide documents how we log in `observability-sensei` and how to adapt it.

## Principles

1. **JSON to stdout** — platforms aggregate logs; don't write to files in containers
2. **Structured fields** — every log line is queryable
3. **Correlation IDs** — tie logs to requests, traces, and deploys
4. **Appropriate levels** — info for normal ops, error for failures

## Implementation

Library: [Pino](https://getpino.io/) via [`examples/node-api/src/logger.ts`](../examples/node-api/src/logger.ts)

HTTP logging: `pino-http` middleware in [`examples/node-api/src/app.ts`](../examples/node-api/src/app.ts)

### Example output

```json
{
  "level": "info",
  "time": "2026-06-27T12:00:00.000Z",
  "service": "observability-sensei-api",
  "version": "1.0.0",
  "environment": "production",
  "requestId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "req": { "method": "GET", "url": "/api/example" },
  "res": { "statusCode": 200 },
  "responseTime": 15,
  "msg": "request completed"
}
```

## Required fields for production

| Field | Source | Why |
|-------|--------|-----|
| `service` | static | Filter in multi-service environments |
| `version` / `deployment.id` | `SERVICE_VERSION` env | Correlate with releases |
| `requestId` | `X-Request-Id` or generated | Follow one request |
| `traceId` | OpenTelemetry | Jump to trace backend |
| `level` | pino | Filter errors vs noise |

## Log levels

| Level | When to use |
|-------|-------------|
| `debug` | Local dev only — verbose internals |
| `info` | Normal operations, request completion |
| `warn` | Degraded but working (retries, fallbacks) |
| `error` | Failures requiring attention |
| `fatal` | Process cannot continue |

## What not to log

- Passwords, API keys, session tokens
- Full credit card numbers, government IDs
- Raw health data or PII without redaction

Use Pino redaction:

```typescript
redact: ['req.headers.authorization', 'password']
```

## Deploy correlation

Set in CI/CD:

```yaml
env:
  SERVICE_VERSION: ${{ github.sha }}
```

Every log line includes `version`. During incidents:

```
filter version = "abc123def" AND level = "error"
```

## Centralized logging options

| Tool | Best for |
|------|----------|
| Loki + Grafana | Kubernetes, label-based queries |
| CloudWatch Logs | AWS workloads |
| Elasticsearch | Full-text search at scale |
| Datadog / New Relic | Managed all-in-one |

## Pipeline integration

After deploy, CI can:

1. Query logs for `level:error` in last 5 minutes
2. Fail if error count > threshold
3. Compare error rate to previous version

This complements metrics-based gates.

## Exercise

1. `LOG_LEVEL=debug npm run dev`
2. Send requests with custom header: `curl -H "X-Request-Id: my-test-123" localhost:3000/api/example`
3. Find `my-test-123` in log output
