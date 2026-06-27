# Lab 01 — Falha no health check

**Objetivo:** Ver o Production Gate falhar quando `/health` está degradado.

## Passos

1. Suba a stack: `npm run stack:up`
2. Confirme health OK: `curl http://localhost:3000/health`
3. Gere erros: `for i in $(seq 1 25); do curl -s http://localhost:3000/api/example/error; done`
4. Health degradado: `curl http://localhost:3000/health` → HTTP **503**
5. Gate: `./examples/scripts/production-gate.sh` → **FAIL**

## Recuperação

```bash
docker compose restart api
./examples/scripts/production-gate.sh
```

Próximo: [Lab 02](./lab-02-error-rate.md)
