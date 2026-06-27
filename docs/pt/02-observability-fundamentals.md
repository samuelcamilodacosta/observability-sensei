# Fundamentos de observabilidade

## Monitoramento vs observabilidade

- **Monitoramento:** perguntas que você já previu (dashboards fixos)  
- **Observabilidade:** investigar o que você ainda não sabia que precisava perguntar  

## Três pilares

| Pilar | Responde |
|-------|----------|
| **Logs** | O que aconteceu? |
| **Métricas** | Quanto / quão rápido? |
| **Traces** | Por que / onde na cadeia? |

## Sinais dourados (SRE)

- **Latência** — tempo de resposta  
- **Tráfego** — demanda  
- **Erros** — taxa de falha  
- **Saturação** — quão cheio o sistema está  

## Método RED (serviços)

- **R**ate — req/s  
- **E**rrors — erros/s  
- **D**uration — duração  

O script `verify-metrics.sh` valida o **E** do RED após deploy.

## Correlação com deploy

Toda release deve carregar `SERVICE_VERSION` ou `deployment.id` em logs, métricas e traces.

Próximo: [Logs, métricas e traces](./03-logs-metrics-traces.md)
