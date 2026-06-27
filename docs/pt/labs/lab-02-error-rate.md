# Lab 02 — Gate por taxa de erro

**Objetivo:** Validar release via métricas.

## Passos

1. `docker compose restart api && sleep 10`
2. Tráfego OK: 20× `curl http://localhost:3000/api/example`
3. `./examples/scripts/verify-metrics.sh` → **OK**
4. 15× `curl .../api/example/error`
5. `./examples/scripts/verify-metrics.sh` → **FAIL**

## Bônus — modo Prometheus

```bash
VERIFY_MODE=prometheus PROMETHEUS_URL=http://localhost:9090 ./examples/scripts/verify-metrics.sh
```

Próximo: [Lab 03](./lab-03-latency.md)
