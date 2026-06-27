# Lab 01 — Health check failure

**Goal:** See the Production Gate fail when `/health` is unhealthy.

## Steps

1. Start the stack:
   ```bash
   npm run stack:up
   # or: docker compose up -d
   ```

2. Confirm health is OK:
   ```bash
   curl http://localhost:3000/health
   ```

3. Generate enough errors to degrade health (>5% error rate):
   ```bash
   for i in $(seq 1 25); do curl -s http://localhost:3000/api/example/error; done
   ```

4. Check health again:
   ```bash
   curl http://localhost:3000/health
   ```

5. Run the gate:
   ```bash
   ./examples/scripts/production-gate.sh
   ```

## Expected result

| Step | Expected |
|------|----------|
| 2 | HTTP 200, `"status":"ok"` |
| 4 | HTTP 503, `"status":"degraded"`, `"error_rate":"degraded"` |
| 5 | Gate **FAIL** — health check step fails |

## Recovery

```bash
docker compose restart api
./examples/scripts/production-gate.sh   # should PROMOTE
```

## What you learned

Health checks in CI/CD must reflect **real readiness**, not just "process is up". The same `/health` endpoint powers Kubernetes readiness probes — see [`examples/k8s/`](../k8s/).

Next: [Lab 02 — Error rate gate](./lab-02-error-rate.md)
