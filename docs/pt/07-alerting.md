# Alertas

## Gate vs alerta

| Mecanismo | Quando | Quem age |
|-----------|--------|----------|
| **Production Gate** | Minutos após deploy | Pipeline |
| **Alerta** | Qualquer momento | On-call |

## Regras Prometheus (local)

Arquivo: [`stacks/prometheus/alerts.yml`](../../stacks/prometheus/alerts.yml)

- `HighErrorRate` — erro > 5% por 2min  
- `HighLatencyP99` — p99 > 500ms  
- `ApiTargetDown` — scrape falhou  

Visualize em Prometheus → Alerts.

## Qualidade de alerta

Todo alerta precisa responder: **o que**, **quem é afetado**, **primeira ação**.

Próximo: [Arquitetura de produção](./08-production-architecture.md)
