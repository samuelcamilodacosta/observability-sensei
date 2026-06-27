# Lab 03 — Latency gate

**Goal:** Trigger Production Gate failure via latency threshold.

## Steps

1. Reset API:
   ```bash
   docker compose restart api && sleep 10
   ```

2. Hit the slow endpoint:
   ```bash
   curl http://localhost:3000/api/example/slow
   ```

3. Run gate with strict latency threshold:
   ```bash
   GATE_MAX_LATENCY_MS=100 GATE_SOAK_SECONDS=1 ./examples/scripts/production-gate.sh
   ```

4. Run with normal threshold (500ms):
   ```bash
   docker compose restart api && sleep 10
   for i in $(seq 1 10); do curl -s http://localhost:3000/api/example > /dev/null; done
   GATE_MAX_LATENCY_MS=500 ./examples/scripts/production-gate.sh
   ```

## Expected result

| Step | Expected |
|------|----------|
| 3 | Gate **FAIL** on latency step (slow route ~600–800ms) |
| 4 | Gate **PROMOTE** with normal traffic |

## Verify in Jaeger

1. Open http://localhost:16686
2. Service: `observability-sensei-api`
3. Find trace for `/api/example/slow` — observe span duration

## What you learned

Latency SLOs belong in the Production Gate alongside error rate. Traces help explain *why* latency failed.

Next: [Lab 04 — Full recovery flow](./lab-04-recovery.md)
