# Production Architecture

This chapter ties everything together: how a production system with observability-first CI/CD actually looks.

## Reference architecture

```
                                    ┌─────────────────────────────────────────┐
                                    │            GitHub Actions               │
                                    │  CI → Build → Deploy → Production Gate  │
                                    └──────────────────┬──────────────────────┘
                                                       │
                                                       ▼
┌──────────┐    ┌──────────────┐    ┌─────────────────────────────────────────┐
│  GitHub  │───▶│   Registry   │───▶│              Kubernetes / VM            │
│   repo   │    │  (ECR/GHCR)  │    │  ┌─────────┐  ┌─────────┐  ┌────────┐ │
└──────────┘    └──────────────┘    │  │ API pod │  │ API pod │  │  ...   │ │
                                    │  └────┬────┘  └────┬────┘  └────────┘ │
                                    └───────┼────────────┼────────────────────┘
                                            │            │
                    ┌───────────────────────┼────────────┼───────────────────────┐
                    │                       ▼            ▼                       │
                    │              ┌─────────────────────────────┐               │
                    │              │     Observability stack      │               │
                    │              │  Prometheus │ Grafana │ OTel│               │
                    │              └─────────────────────────────┘               │
                    │                       │                                    │
                    │                       ▼                                    │
                    │              ┌─────────────────────────────┐               │
                    │              │   Logs (Loki / CloudWatch)  │               │
                    │              └─────────────────────────────┘               │
                    └────────────────────────────────────────────────────────────┘
```

## Service responsibilities

| Component | Role |
|-----------|------|
| API service | Business logic + `/health` + `/metrics` + OTel |
| Prometheus | Scrape metrics, evaluate alert rules |
| Grafana | Dashboards, SLO views, deploy annotations |
| OpenTelemetry Collector | Receive traces; export to backend |
| CI/CD | Build, test, deploy, gate, rollback |
| Alertmanager | Route pages to on-call |

## Local stack mapping

`docker-compose.yml` in this repo is a **minimal** version:

| Production | Local equivalent |
|------------|------------------|
| K8s deployment | `api` container |
| Prometheus | `prometheus` service |
| Grafana | `grafana` service |
| OTel Collector | Console exporter in dev |

## Security essentials

- **Secrets** in vault / GitHub Environments — never in images
- **OIDC** for cloud deploy from Actions — no long-lived keys
- **Network policies** — metrics endpoint internal only
- **Image scanning** in CI — add Trivy or similar to your fork

## Scalability path

| Stage | Team size | Setup |
|-------|-----------|-------|
| 1 | 1–5 | This repo: single API, compose stack |
| 2 | 5–20 | K8s, managed Prometheus, central logs |
| 3 | 20+ | Multi-region, SLOs, error budgets, canary platform |

## Production readiness checklist

### Application

- [ ] Structured logging to stdout
- [ ] `/health` live + ready (or combined with clear docs)
- [ ] `/metrics` with RED metrics
- [ ] OpenTelemetry traces with service.name + version
- [ ] Graceful shutdown (SIGTERM handling)

### Pipeline

- [ ] CI: test + build on every PR
- [ ] CD: immutable artifacts tagged with SHA
- [ ] Post-deploy health check
- [ ] Metrics validation
- [ ] Production Gate with rollback

### Operations

- [ ] Dashboards for golden signals
- [ ] Alerts with runbooks
- [ ] Rollback tested quarterly
- [ ] DORA metrics tracked

## Where to go from here

1. Fork this repo and wire `deploy-with-observability.yml` to your cloud
2. Replace `deploy-mock.sh` with real deploy commands
3. Point `verify-metrics.sh` at your Prometheus API
4. Add Trivy, SAST, and dependency scanning to CI
5. Introduce canary deploys when single-instance gates aren't enough

## Final thought

Production readiness isn't a checklist you finish once. It's a loop:

```
Ship → Observe → Learn → Improve gates → Ship again
```

That's observability-sensei. **Ship with confidence, not hope.**
