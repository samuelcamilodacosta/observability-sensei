# Release Observability

Release observability means treating every deploy as an experiment you can measure — not a ceremony you hope went well.

## The release validation flow

```
┌─────────┐     ┌──────────────┐     ┌─────────────────┐     ┌──────────┐
│ Deploy  │────▶│ Health check │────▶│ Metrics verify  │────▶│   Gate   │
│ v1.2.3  │     │   /health    │     │ error + latency │     │ promote? │
└─────────┘     └──────────────┘     └─────────────────┘     └──────────┘
                                                                    │
                                          ┌─────────────────────────┴─────────────────────────┐
                                          ▼                                                   ▼
                                    ✅ Promote                                           ❌ Rollback
```

## Post-deploy health check

The first question after deploy: **is the process alive and ready?**

Our health endpoint returns:

```json
{
  "status": "ok",
  "uptime": 123.45,
  "version": "1.0.0",
  "checks": {
    "memory": "ok",
    "dependencies": "ok"
  }
}
```

Script: [`examples/scripts/health-check.sh`](../examples/scripts/health-check.sh)

### Liveness vs readiness

| Probe | Question | K8s probe |
|-------|----------|-----------|
| Liveness | Is the process deadlocked? | Restart if fail |
| Readiness | Can it accept traffic? | Remove from LB if fail |

`/health` in our example combines both for simplicity. In production, split `/health/live` and `/health/ready`.

## Metrics validation step

Health only tells you the app responds. Metrics tell you if it's **behaving correctly**.

After deploy, wait a soak period (30s–5min depending on traffic), then:

1. Scrape metrics
2. Compare error rate to baseline
3. Check latency percentiles

Script: [`examples/scripts/verify-metrics.sh`](../examples/scripts/verify-metrics.sh)

## The Production Gate

The **Production Gate** is the decision stage. It combines multiple signals:

| Check | Default threshold | Env var |
|-------|-------------------|---------|
| Health | HTTP 200, `status: ok` | `GATE_HEALTH_URL` |
| Error rate | &lt; 5% | `GATE_MAX_ERROR_RATE` |
| Latency (p99 sim) | &lt; 500ms | `GATE_MAX_LATENCY_MS` |

Script: [`examples/scripts/production-gate.sh`](../examples/scripts/production-gate.sh)

### Gate logic (simplified)

```bash
health_ok && error_rate_ok && latency_ok → PROMOTE
otherwise → ROLLBACK
```

In production you'd:

- Query Prometheus or your APM
- Compare canary vs stable
- Use feature flag systems for gradual rollout

Our scripts **simulate** error rate and latency checks so you can run the full pipeline locally without historical data.

## Canary and blue-green (conceptual)

| Strategy | Observability focus |
|----------|---------------------|
| **Blue-green** | Switch traffic; gate on full metrics slice |
| **Canary** | 5% traffic first; gate before 100% |
| **Rolling** | Old + new pods; watch error rate per version label |

The Production Gate works with any strategy — it's the **decision layer**, not the deploy mechanism.

## Release metadata

Stamp every deploy with:

```yaml
env:
  DEPLOY_VERSION: ${{ github.sha }}
  DEPLOY_TIMESTAMP: ${{ github.event.head_commit.timestamp }}
```

The API reads `SERVICE_VERSION` and exposes it in `/health` and logs.

## Failure scenarios to practice

1. Deploy with API down → health check fails → rollback
2. Hit `/api/example/error` repeatedly → metrics gate fails
3. Set `GATE_MAX_LATENCY_MS=1` → latency gate fails

## Exercise

1. Read [`examples/github-actions/deploy-with-observability.yml`](../examples/github-actions/deploy-with-observability.yml)
2. Run the API and execute `./examples/scripts/production-gate.sh`
3. Break it: `curl` the error endpoint 10 times, re-run the gate

Next: [DORA metrics](./05-dora-metrics.md)
