# Logs, métricas e traces

## Logs estruturados

Implementação: [`examples/node-api/src/logger.ts`](../../examples/node-api/src/logger.ts) (Pino + JSON).

Campos essenciais: `service`, `version`, `requestId`, `traceId`, `level`.

Estratégia completa: [`stacks/logging-strategy.md`](../../stacks/logging-strategy.md)  
Loki em produção: [`stacks/logging-loki.md`](../../stacks/logging-loki.md)

## Métricas (Prometheus)

Endpoint: `GET /metrics`

| Métrica | Tipo |
|---------|------|
| `http_requests_total` | Counter |
| `http_request_errors_total` | Counter |
| `http_request_duration_seconds` | Histogram |

Query exemplo:

```promql
sum(rate(http_request_errors_total[5m])) / sum(rate(http_requests_total[5m]))
```

Modo PromQL no script:

```bash
VERIFY_MODE=prometheus PROMETHEUS_URL=http://localhost:9090 ./examples/scripts/verify-metrics.sh
```

## Traces (OpenTelemetry)

Código: [`examples/node-api/src/telemetry.ts`](../../examples/node-api/src/telemetry.ts)

Com stack Docker: traces visíveis em **Jaeger** → http://localhost:16686

## Endpoints de teste

| Rota | Uso |
|------|-----|
| `/api/example` | Tráfego saudável |
| `/api/example/error` | Simular erros |
| `/api/example/slow` | Simular latência alta |

Próximo: [Observabilidade de release](./04-release-observability.md)
