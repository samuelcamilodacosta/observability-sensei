# Arquitetura de produção

## Stack local → produção

| Local | Produção |
|-------|----------|
| `docker compose` | Kubernetes / ECS / VM |
| Prometheus | Managed Prometheus / Mimir |
| Grafana | Grafana Cloud / self-hosted |
| Jaeger | Tempo / Honeycomb / Datadog |
| Scripts bash | Mesmos scripts no GitHub Actions |

## Kubernetes

Exemplo mínimo: [`examples/k8s/`](../../examples/k8s/) — Deployment com `livenessProbe` e `readinessProbe` em `/health`.

## Checklist de prontidão

**App:** logs JSON, `/health`, `/metrics`, OTel, SIGTERM graceful  

**Pipeline:** CI, artefato imutável, health pós-deploy, gate, rollback  

**Ops:** dashboard RED, alertas com runbook, rollback testado  

## Loop contínuo

```
Ship → Observe → Learn → Improve gates → Ship again
```

**Ship with confidence, not hope.**
