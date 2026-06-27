# Lab 02 — Error rate gate

**Goal:** Validate metrics-based release verification using `verify-metrics.sh`.

## Steps

1. Reset API (clean metrics):
   ```bash
   docker compose restart api && sleep 10
   ```

2. Generate healthy traffic:
   ```bash
   for i in $(seq 1 20); do curl -s http://localhost:3000/api/example > /dev/null; done
   ```

3. Run metrics validation:
   ```bash
   ./examples/scripts/verify-metrics.sh http://localhost:3000/metrics
   ```

4. Inject errors:
   ```bash
   for i in $(seq 1 15); do curl -s http://localhost:3000/api/example/error; done
   ```

5. Run validation again:
   ```bash
   ./examples/scripts/verify-metrics.sh http://localhost:3000/metrics
   ```

6. **Bonus** — Prometheus mode (requires stack running 5+ min for rates, or use after traffic):
   ```bash
   VERIFY_MODE=prometheus PROMETHEUS_URL=http://localhost:9090 ./examples/scripts/verify-metrics.sh
   ```

## Expected result

| Step | Expected |
|------|----------|
| 3 | `OK: error rate within threshold` |
| 5 | `FAIL: error rate ... exceeds max 0.05` |

## Verify in Grafana

Open http://localhost:3001 → **observability-sensei API** dashboard → watch **Error Rate** panel spike after step 4.

## What you learned

Post-deploy validation uses **metrics**, not just HTTP 200. Production teams query Prometheus with PromQL; our script supports `VERIFY_MODE=prometheus`.

Next: [Lab 03 — Latency gate](./lab-03-latency.md)
