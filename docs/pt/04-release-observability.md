# Observabilidade de release

## Fluxo pós-deploy

```
Deploy → Health check → Métricas → Production Gate → Promote ou Rollback
```

## Production Gate

Script: [`examples/scripts/production-gate.sh`](../../examples/scripts/production-gate.sh)

| Check | Limiar padrão |
|-------|---------------|
| Health | HTTP 200, `status: ok` |
| Taxa de erro | < 5% |
| Latência p99 | < 500ms |

Variáveis: `GATE_MAX_ERROR_RATE`, `GATE_MAX_LATENCY_MS`, `GATE_HEALTH_URL`

## Canary (gradual)

Simulação: [`examples/scripts/canary-mock.sh`](../../examples/scripts/canary-mock.sh)

Tráfego parcial → gate → promote 100% ou rollback.

## Anotação no Grafana

Após deploy:

```bash
DEPLOY_VERSION=abc123 ./examples/scripts/annotate-deploy-grafana.sh
```

## Labs

Faça na prática: [labs/](./labs/)

Próximo: [Métricas DORA](./05-dora-metrics.md)
