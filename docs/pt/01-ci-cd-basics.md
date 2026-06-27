# CI/CD básico

## CI vs CD

| Termo | Pergunta |
|-------|----------|
| **CI** | A mudança quebra build ou testes? |
| **CD (Delivery)** | Podemos liberar agora? |
| **CD (Deployment)** | Liberamos automaticamente? |

Este repo usa **Delivery** + **Production Gate** como aprovação baseada em sinais de produção.

## Pipeline CI mínimo

1. `npm ci` — dependências reproduzíveis  
2. `npm test` — regressões  
3. `npm run build` — artefato compilado  

Arquivo: [`examples/github-actions/ci.yml`](../../examples/github-actions/ci.yml)

## Pipeline CD mínimo

1. Deploy  
2. Smoke test / health check  
3. Notificação  

O pipeline com observabilidade adiciona validação de métricas e gate.

## Erros comuns

- Testar só em produção  
- Rebuild diferente no deploy  
- Deploy sem ID de versão nos logs/métricas  

Próximo: [Fundamentos de observabilidade](./02-observability-fundamentals.md)
