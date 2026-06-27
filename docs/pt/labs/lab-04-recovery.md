# Lab 04 — Fluxo completo de recuperação

**Objetivo:** Deploy → falha → rollback → recuperação → promote.

## Passos

1. `npm run demo`
2. `DEPLOY_VERSION=v2-bad ./examples/scripts/deploy-mock.sh`
3. 30× requests em `/api/example/error`
4. `./examples/scripts/production-gate.sh || ./examples/scripts/rollback.sh`
5. `docker compose restart api`
6. (Opcional) `./examples/scripts/canary-mock.sh`
7. `./examples/scripts/production-gate.sh` → **PROMOTE**

## Checklist

- [ ] Vi rollback restaurar versão  
- [ ] Vi erro no dashboard Grafana  
- [ ] (Opcional) Vi trace no Jaeger  

[← Voltar ao índice PT](../README.md)
