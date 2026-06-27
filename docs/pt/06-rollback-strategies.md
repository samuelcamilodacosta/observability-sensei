# Estratégias de rollback

## Princípios

1. Automatize  
2. Ensaie antes do incidente  
3. Volte para artefato/imagem conhecida — não rebuild  
4. Valide health + métricas após rollback  

## Script deste repo

[`examples/scripts/rollback.sh`](../../examples/scripts/rollback.sh) — restaura versão em `.deploy-state/previous-version`

## Estratégias

| Cenário | Abordagem |
|---------|-----------|
| Código ruim | Redeploy versão anterior / `kubectl rollout undo` |
| Feature flag | Desligar flag |
| Migração destrutiva | Expand/contract — nunca rollback automático de DROP |

## No pipeline

Se Production Gate falha → `rollback.sh` automático.

Veja workflow: [`.github/workflows/deploy-with-observability.yml`](../../.github/workflows/deploy-with-observability.yml)

Próximo: [Alertas](./07-alerting.md)
