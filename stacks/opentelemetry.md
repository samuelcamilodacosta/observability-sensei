# OpenTelemetry integration guide

This repo instruments the sample API with OpenTelemetry (OTel) for distributed tracing.

## What's instrumented

| Layer | Implementation |
|-------|----------------|
| HTTP server | `@opentelemetry/auto-instrumentations-node` |
| Custom spans | `example.handler`, `health.check` in route files |
| Resource attrs | `service.name`, `service.version` |

Code: [`examples/node-api/src/telemetry.ts`](../examples/node-api/src/telemetry.ts)

## Initialization order matters

OpenTelemetry must load **before** Express:

```typescript
// server.ts — first import
import './telemetry';
import app from './app';
```

If you import Express first, auto-instrumentation misses HTTP spans.

## Export modes

### Development (default)

No `OTEL_EXPORTER_OTLP_ENDPOINT` → traces via auto-instrumentation only (no external export in minimal setup).

### OTLP to collector

```bash
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
npm run dev
```

Compatible with OpenTelemetry Collector, Jaeger, Grafana Tempo, Honeycomb, Datadog, etc.

### Docker Compose

The optional collector in `docker-compose.yml` receives OTLP on port 4318.

## W3C trace context

OTel propagates `traceparent` headers automatically. When you add a second service:

```
Client → API (trace id: abc) → downstream service (same trace id)
```

Logs include `traceId` when using correlated logging middleware.

## Custom spans example

```typescript
import { trace, SpanStatusCode } from '@opentelemetry/api';

const tracer = trace.getTracer('observability-sensei-api');
const span = tracer.startSpan('example.handler');

try {
  span.setAttribute('user.tier', 'premium');
  // business logic
} catch (err) {
  span.recordException(err);
  span.setStatus({ code: SpanStatusCode.ERROR });
  throw err;
} finally {
  span.end();
}
```

## Traces in release validation

Production teams sometimes gate on:

- **Trace error rate** — % of traces with error status after deploy
- **New route coverage** — canary requests produce expected spans

Our Production Gate uses metrics for simplicity; extend with Tempo/Jaeger queries for trace-based gates.

## Sampling

In high-traffic production, use head-based sampling:

```bash
export OTEL_TRACES_SAMPLER=parentbased_traceidratio
export OTEL_TRACES_SAMPLER_ARG=0.1
```

Always sample errors in your backend collector when possible.

## Exercise

1. Set `OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318`
2. Run API and hit `/api/example`
3. Verify spans in your collector UI (if running compose stack)
