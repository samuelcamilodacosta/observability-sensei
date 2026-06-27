# Lab 03 — Gate por latência

**Objetivo:** Falhar o gate por latência p99.

## Passos

1. `curl http://localhost:3000/api/example/slow`
2. `GATE_MAX_LATENCY_MS=100 ./examples/scripts/production-gate.sh` → **FAIL**
3. Reinicie API, tráfego normal, `GATE_MAX_LATENCY_MS=500` → **PROMOTE**

## Jaeger

http://localhost:16686 → serviço `observability-sensei-api` → trace de `/api/example/slow`

Próximo: [Lab 04](./lab-04-recovery.md)
