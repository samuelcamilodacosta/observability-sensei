# CI/CD Basics

Before observability, you need a pipeline that actually runs. This chapter covers the foundation every team shares — and where most teams stop too early.

## CI vs CD

| Term | Meaning | Question it answers |
|------|---------|---------------------|
| **CI** (Continuous Integration) | Merge code frequently; validate on every change | Does this change break the build or tests? |
| **CD** (Continuous Delivery) | Code is always deployable | Can we release this right now? |
| **CD** (Continuous Deployment) | Every merge goes to production automatically | Did we release this automatically? |

This repo uses **Continuous Delivery** patterns: deploy steps exist, but the **Production Gate** is the human-or-automated approval based on observability signals.

## Minimal CI pipeline

Our CI pipeline ([`examples/github-actions/ci.yml`](../examples/github-actions/ci.yml)) does three things:

1. **Install dependencies** — reproducible `npm ci`
2. **Run tests** — catch regressions before merge
3. **Build** — prove TypeScript compiles and artifacts exist

```yaml
- run: npm ci
- run: npm test
- run: npm run build
```

That's table stakes. Without it, everything downstream is noise.

## Minimal CD pipeline

CD adds:

1. **Deploy** — push container or artifact to an environment
2. **Smoke test** — basic "is it up?" check
3. **Notify** — tell the team what happened

Our CD example stops at deploy + health check. The observability pipeline adds metrics and the Production Gate.

## Branch strategy (pragmatic)

We don't prescribe GitFlow vs trunk-based. What matters:

- **main** is deployable at all times
- Feature branches run CI on every push
- Production deploys are traceable to a commit SHA

Tag releases or use commit SHA in your deploy manifest. You'll need it for rollback.

## Environment progression

```
dev → staging → production
         │
         └── observability checks get stricter at each stage
```

- **dev**: loose thresholds, fast iteration
- **staging**: same checks as production, synthetic traffic
- **production**: Production Gate with real SLOs

## Common mistakes

1. **Skipping tests in CD** — "we'll test in prod" (you will, painfully)
2. **No artifact immutability** — rebuilding different code at deploy time
3. **Secrets in workflow files** — use GitHub Environments and OIDC
4. **No deploy ID** — you can't correlate logs/metrics to a release

## Exercise

1. Open [`examples/github-actions/ci.yml`](../examples/github-actions/ci.yml)
2. Run locally: `cd examples/node-api && npm ci && npm test && npm run build`
3. Identify what would fail if you broke the `/health` route

Next: [Observability fundamentals](./02-observability-fundamentals.md)
