# Rollback Strategies

When the Production Gate fails, you need a rehearsed path back — not a panicked Slack thread.

## Rollback principles

1. **Automate it** — humans are slow under pressure
2. **Practice it** — untested rollbacks fail when you need them
3. **Keep artifacts** — rollback to a known image/tag, not a rebuild
4. **Verify after rollback** — run the same health + metrics checks

## Strategies

### 1. Redeploy previous version (most common)

```
current: v1.2.3 (bad)
rollback: redeploy v1.2.2 (last known good)
```

Our script: [`examples/scripts/rollback.sh`](../examples/scripts/rollback.sh)

Stores state in `.deploy-state/previous-version`. In production, use your container registry tags or K8s rollout undo.

### 2. Kubernetes rollout undo

```bash
kubectl rollout undo deployment/my-api -n production
kubectl rollout status deployment/my-api -n production
```

Fast, built-in, uses ReplicaSet history.

### 3. Blue-green switch

Flip load balancer back to blue environment. Zero rebuild — instant if blue is still warm.

### 4. Feature flags

Disable the feature without redeploying. Best for **logic bugs**, not infra failures.

| Failure type | Best rollback |
|--------------|---------------|
| Bad code | Redeploy / K8s undo |
| Config error | Revert config + redeploy |
| Feature logic | Flag off |
| Database migration | Forward-fix or expand-contract pattern |

## Rollback in the pipeline

From [`deploy-with-observability.yml`](../examples/github-actions/deploy-with-observability.yml):

```yaml
- name: Production Gate
  id: gate
  run: ./examples/scripts/production-gate.sh

- name: Rollback on failure
  if: failure() && steps.gate.outcome == 'failure'
  run: ./examples/scripts/rollback.sh
```

Key points:

- Rollback runs **only** when gate fails
- Same scripts work locally and in CI
- Notify team after rollback (add Slack/webhook in your fork)

## Database rollbacks

**Rule:** avoid destructive migrations in automated rollback paths.

Use **expand/contract**:

1. Expand — add new column/table (backward compatible)
2. Deploy new code using new schema
3. Contract — remove old column in a later release

Never auto-rollback a migration that dropped data.

## Rollback checklist

- [ ] Previous version artifact exists and is pullable
- [ ] Rollback script tested in staging this quarter
- [ ] Health + metrics checks run post-rollback
- [ ] Incident channel notified with version SHA
- [ ] Post-incident: why did gate miss it (if applicable)?

## Exercise

1. Deploy "v1": `DEPLOY_VERSION=v1.0.0 ./examples/scripts/deploy-mock.sh`
2. Deploy "v2": `DEPLOY_VERSION=v2.0.0 ./examples/scripts/deploy-mock.sh`
3. Run `./examples/scripts/rollback.sh`
4. Confirm `.deploy-state/current-version` shows v1.0.0

Next: [Alerting](./07-alerting.md)
