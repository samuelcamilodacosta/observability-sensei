# Observability Fundamentals

Observability is the ability to understand the internal state of a system from its external outputs — without deploying new code to ask new questions.

## Monitoring vs observability

| Monitoring | Observability |
|------------|---------------|
| Known unknowns (dashboards you built) | Unknown unknowns (ad-hoc investigation) |
| "Is CPU high?" | "Why are checkout requests slow for EU users?" |
| Threshold alerts | Explorable telemetry |

You need both. Monitoring catches regressions. Observability helps you debug novel failures.

## The three pillars

```
        ┌─────────┐
        │  LOGS   │  Discrete events — what happened?
        └────┬────┘
             │
   ┌─────────┼─────────┐
   │         │         │
┌──▼──┐  ┌───▼───┐  ┌──▼──┐
│TRACE│  │METRICS│  │LOGS │
└─────┘  └───────┘  └─────┘
  Why?    How much?   What?
```

1. **Logs** — structured records of events
2. **Metrics** — aggregated numbers over time
3. **traces** — request paths across services

In CI/CD, these pillars answer post-deploy questions:

- Did error rate increase after this SHA?
- Is latency within SLO?
- Which dependency broke first?

## Golden signals (Google SRE)

For any user-facing service, instrument:

| Signal | Meaning | Pipeline use |
|--------|---------|--------------|
| **Latency** | Time to serve requests | Gate on p99 |
| **Traffic** | Demand on the system | Detect deploy during low traffic |
| **Errors** | Rate of failed requests | Gate on error % |
| **Saturation** | How "full" the system is | Scale decisions |

## Observability in the deploy lifecycle

```
Deploy ──▶ Emit version tag in telemetry ──▶ Query by version ──▶ Compare to baseline
```

Every deploy should stamp:

- `service.version` or `deployment.id` in logs
- Same label on metrics
- Trace resource attributes

Without version labels, you cannot do release validation.

## RED method (services)

- **R**ate — requests per second
- **E**rrors — failed requests per second
- **D**uration — time per request

Our `verify-metrics.sh` script checks RED-style counters from the `/metrics` endpoint.

## USE method (resources)

- **U**tilization
- **S**aturation
- **E**rrors

Useful for nodes and databases; less common in app-level pipeline gates.

## What "good enough" looks like

You don't need a full observability platform on day one:

1. Structured JSON logs to stdout
2. `/health` and `/metrics` endpoints
3. One dashboard with error rate and latency
4. Pipeline step that queries metrics after deploy

This repo implements exactly that baseline.

## Exercise

1. Start the API: `cd examples/node-api && npm run dev`
2. Hit `GET /api/example` and `GET /api/example/error`
3. Read the JSON logs in your terminal — notice `requestId` and `traceId`

Next: [Logs, metrics, and traces in practice](./03-logs-metrics-traces.md)
