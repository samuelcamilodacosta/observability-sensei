# Logs com Loki (estratégia)

Este guia complementa [`logging-strategy.md`](logging-strategy.md) com o caminho natural em produção: **logs estruturados → Loki → Grafana**.

## Stack local (já incluída)

O `docker-compose.yml` sobe **Loki** + **Promtail** automaticamente:

| Serviço | URL | Função |
|---------|-----|--------|
| Loki | http://localhost:3100 | Armazena logs |
| Promtail | (interno) | Coleta logs dos containers Docker |
| Grafana Explore | http://localhost:3001 | Query LogQL |

Config: [`stacks/promtail/promtail-config.yaml`](promtail/promtail-config.yaml)

## Por que Loki?

| Ferramenta | Modelo | Ideal para |
|------------|--------|------------|
| Elasticsearch | Indexação full-text | Busca complexa em texto |
| **Loki** | Labels como Prometheus | Logs correlacionados com métricas |
| CloudWatch | Managed AWS | Workloads na AWS |

Loki usa os **mesmos labels** que Prometheus (`service`, `version`, `environment`), facilitando correlação deploy → erro.

## Fluxo

```
API (JSON stdout) → Docker logs → Promtail → Loki → Grafana Explore
```

## Exemplo de query (LogQL)

No Grafana → **Explore** → datasource **Loki**:

```logql
{compose_service="api"} | json | level="error"
```

Filtrar por versão de deploy:

```logql
{compose_service="api"} | json | version="docker-compose"
```

Correlacionar com trace:

```logql
{compose_service="api"} | json | traceId="4bf92f3577b34da6"
```

## Gerar logs para testar

```powershell
npm run traffic:ps1 -- -Ok 10 -Errors 5
```

Depois abra Grafana Explore e rode a query acima.

## Pipeline CI/CD

Após deploy, valide logs de erro:

```bash
curl -G "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={compose_service="api"} | json | level="error"' \
  --data-urlencode "start=$(date -d '5 min ago' +%s)000000000"
```

Se contagem de erros > limiar → falhar gate (mesmo padrão de `verify-metrics.sh`).

## Campos obrigatórios nos logs

Veja implementação em [`examples/node-api/src/logger.ts`](../examples/node-api/src/logger.ts):

- `service`, `version`, `level`, `requestId`, `traceId`

Isso permite queries consistentes em Loki, Datadog ou CloudWatch.
