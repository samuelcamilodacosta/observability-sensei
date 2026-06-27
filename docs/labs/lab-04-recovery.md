# Lab 04 — Full recovery flow

**Goal:** Deploy → gate fails → rollback → recover → promote.

## Steps

1. Ensure stack is healthy:
   ```bash
   npm run demo
   ```

2. Simulate a bad release:
   ```bash
   DEPLOY_VERSION=v2-bad ./examples/scripts/deploy-mock.sh
   for i in $(seq 1 30); do curl -s http://localhost:3000/api/example/error; done
   ```

3. Gate should fail — run rollback:
   ```bash
   ./examples/scripts/production-gate.sh || ./examples/scripts/rollback.sh
   cat .deploy-state/current-version
   ```

4. Recover service:
   ```bash
   docker compose restart api && sleep 10
   ```

5. Annotate deploy in Grafana (optional):
   ```bash
   DEPLOY_VERSION=recovered ./examples/scripts/annotate-deploy-grafana.sh
   ```

6. Canary pattern (optional):
   ```bash
   docker compose restart api && sleep 10
   ./examples/scripts/canary-mock.sh
   ```

7. Final gate:
   ```bash
   for i in $(seq 1 10); do curl -s http://localhost:3000/api/example > /dev/null; done
   ./examples/scripts/production-gate.sh
   ```

## Expected result

| Step | Expected |
|------|----------|
| 3 | Gate fails; rollback restores previous version in `.deploy-state` |
| 6 | Canary passes → promoted version written |
| 7 | `✅ PRODUCTION GATE: PROMOTE` |

## Checklist

- [ ] Understood deploy → observe → decide → act loop
- [ ] Saw rollback script restore version
- [ ] Saw Grafana dashboard reflect error spike
- [ ] (Optional) Saw trace in Jaeger

## What you learned

This is observability-first CI/CD: **automated decision** after deploy, not hope.

Return to [docs index](../00-intro.md) or read [Portuguese docs](../../pt/README.md).
