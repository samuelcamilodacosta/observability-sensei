# observability-sensei — Documentação em Português

> **Ship with confidence, not hope.**  
> Entregue com confiança, não com esperança.

Documentação completa em português. Versão em inglês: [`../00-intro.md`](../00-intro.md) e [`../../README.md`](../../README.md).

## Screenshots

| Grafana — dashboard RED | Production Gate |
|:---:|:---:|
| ![Grafana](../images/grafana-dashboard.png) | ![Production Gate](../images/production-gate.png) |

---

## Trilhas de aprendizado

| Nível | Tempo | O que você faz |
|-------|-------|----------------|
| **Level 1** | ~30 min | API local + `/health` + scripts de health check |
| **Level 2** | ~1 h | Docker + Prometheus + Grafana + Loki + Jaeger |
| **Level 3** | ~2 h | Production Gate + rollback + canary + labs |

### Level 1 — Fundamentos

```bash
cd examples/node-api && npm install && npm run dev
# outro terminal:
curl http://localhost:3000/health
./examples/scripts/health-check.sh
```

Leia: [00-intro](./00-intro.md) → [01-ci-cd-basics](./01-ci-cd-basics.md)

### Level 2 — Observabilidade visual

```bash
npm run stack:up    # ou: npm run demo
```

| Script | Uso |
|--------|-----|
| `npm run traffic:ps1 -- -Ok 30` | Só gera requests (PowerShell) |
| `npm run traffic -- --ok 30 --errors 10` | Git Bash / Linux / Mac |
| `npm run gate` | Production Gate manual |

- Grafana: http://localhost:3001 (admin / sensei)
- Prometheus: http://localhost:9090
- Loki: Grafana → Explore → datasource **Loki** (`{compose_service="api"} | json`)
- Jaeger: http://localhost:16686

Leia: [02-observability-fundamentals](./02-observability-fundamentals.md) → [03-logs-metrics-traces](./03-logs-metrics-traces.md)

### Level 3 — Production Gate

```bash
./examples/scripts/production-gate.sh
./examples/scripts/canary-mock.sh
```

Labs práticos: [labs/](./labs/)

Leia: [04-release-observability](./04-release-observability.md) → [06-rollback-strategies](./06-rollback-strategies.md)

---

## Guias

| # | Tópico | Arquivo |
|---|--------|---------|
| 00 | Introdução | [00-intro.md](./00-intro.md) |
| 01 | CI/CD básico | [01-ci-cd-basics.md](./01-ci-cd-basics.md) |
| 02 | Fundamentos de observabilidade | [02-observability-fundamentals.md](./02-observability-fundamentals.md) |
| 03 | Logs, métricas e traces | [03-logs-metrics-traces.md](./03-logs-metrics-traces.md) |
| 04 | Observabilidade de release | [04-release-observability.md](./04-release-observability.md) |
| 05 | Métricas DORA | [05-dora-metrics.md](./05-dora-metrics.md) |
| 06 | Estratégias de rollback | [06-rollback-strategies.md](./06-rollback-strategies.md) |
| 07 | Alertas | [07-alerting.md](./07-alerting.md) |
| 08 | Arquitetura de produção | [08-production-architecture.md](./08-production-architecture.md) |

## Labs hands-on

| Lab | Objetivo |
|-----|----------|
| [Lab 01](./labs/lab-01-health-gate.md) | Falha no health check |
| [Lab 02](./labs/lab-02-error-rate.md) | Gate por taxa de erro |
| [Lab 03](./labs/lab-03-latency.md) | Gate por latência |
| [Lab 04](./labs/lab-04-recovery.md) | Deploy → falha → rollback → recuperação |

## Quickstart (5 minutos)

```bash
git clone https://github.com/samuelcamilodacosta/observability-sensei.git
cd observability-sensei
npm run demo          # Linux/Mac/Git Bash
# Windows PowerShell:
npm run demo:ps1
```

## Extras

- Kubernetes: [`examples/k8s/`](../../examples/k8s/)
- Canary mock: [`examples/scripts/canary-mock.sh`](../../examples/scripts/canary-mock.sh)
- Logs + Loki: [`stacks/logging-loki.md`](stacks/logging-loki.md)
