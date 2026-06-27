# Alerting

Alerts tell humans something needs attention. Bad alerts train teams to ignore pages. Good alerts are **actionable, urgent, and rare**.

## Alerting vs pipeline gates

| Mechanism | When | Who acts |
|-----------|------|----------|
| **Production Gate** | During deploy (minutes) | Pipeline (auto rollback) |
| **Alert** | Anytime in production | On-call engineer |

Gates prevent bad releases from staying live. Alerts catch everything else — dependency failures, traffic spikes, slow burns.

## Symptoms vs causes

Alert on **user-visible symptoms**:

- High error rate on `/api/checkout`
- p99 latency above SLO

Avoid alerting on causes unless they're clearly actionable:

- CPU at 70% — maybe not
- CPU at 95% for 10min with rising latency — yes

## RED-based alert examples

```yaml
# Pseudo-alert rules (Prometheus Alertmanager style)
- alert: HighErrorRate
  expr: |
    rate(http_request_errors_total[5m])
    / rate(http_requests_total[5m]) > 0.05
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "Error rate above 5% for 5 minutes"

- alert: HighLatency
  expr: |
    histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m])) > 0.5
  for: 5m
  labels:
    severity: warning
```

## Alert quality checklist

Every alert should answer:

1. **What** is wrong?
2. **Who** is affected?
3. **What** should I do first?

If you can't answer #3, it's a ticket, not a page.

## Severity levels

| Level | Response | Example |
|-------|----------|---------|
| Critical | Page immediately | Complete service outage |
| Warning | Next business day or slack | Elevated errors, under SLO |
| Info | Dashboard only | Deploy completed |

## Runbooks

Link every alert to a runbook:

```markdown
## HighErrorRate

1. Check recent deploys: `kubectl rollout history`
2. Compare error rate by version in Grafana
3. If correlated with deploy → rollback
4. If not → check dependencies (DB, cache)
```

## Alert fatigue antidotes

- **SLO-based alerting** — burn rate alerts fire when you're consuming error budget
- **Grouping** — one notification per incident, not per pod
- **Silence during maintenance** — with auto-expiry
- **Weekly alert review** — delete alerts nobody acts on

## Deploy-related alerts

After enabling observability CI/CD, add:

| Alert | Purpose |
|-------|---------|
| Deploy succeeded | Audit trail |
| Production Gate failed | Team awareness even if rollback auto-ran |
| Error rate spike within 15min of deploy | Catch gates that were too loose |

## Exercise

1. Open Grafana at http://localhost:3001 (after `docker compose up`)
2. Imagine an error rate graph — when would you page vs wait?
3. Write a 5-line runbook for "API returning 500s"

Next: [Production architecture](./08-production-architecture.md)
