# DORA Metrics

DORA (DevOps Research and Assessment) metrics measure software delivery performance. Observability-first CI/CD directly improves all four.

## The four keys

| Metric | Definition | Elite benchmark (indicative) |
|--------|------------|------------------------------|
| **Deployment frequency** | How often you deploy to production | On demand (multiple per day) |
| **Lead time for changes** | Commit to production | Less than one day |
| **Change failure rate** | % of deploys causing failure | 0–15% |
| **Time to restore (MTTR)** | Time to recover from failure | Less than one hour |

## How observability improves each metric

### Deployment frequency

**Blocker without observability:** fear of breaking prod slows releases.

**With observability:** automated gates catch bad releases fast → teams deploy smaller changes more often.

### Lead time for changes

**Blocker:** manual verification and long QA cycles.

**With observability:** pipeline validates in production → less manual soak testing.

### Change failure rate

**Blocker:** you only know a deploy failed when users complain.

**With observability:** Production Gate fails before users feel pain → failures are caught early (canary) or reverted quickly.

### Time to restore (MTTR)

**Blocker:** no clear rollback path; debugging takes hours.

**With observability:**
- `rollback.sh` reverts to last known good
- Logs/metrics/traces tagged with version → root cause in minutes

## Mapping repo artifacts to DORA

| Artifact | DORA impact |
|----------|-------------|
| CI pipeline | Enables frequent, safe merges |
| Production Gate | Lowers change failure rate |
| `rollback.sh` | Reduces MTTR |
| Version-tagged metrics | Faster incident correlation |
| Structured logs | Faster debugging |

## Measuring in your org

You don't need DORA consultants on day one:

1. **Deployment frequency** — count deploy workflow runs per week
2. **Lead time** — `deploy_time - commit_time` from GitHub API
3. **Change failure rate** — failed Production Gates / total deploys
4. **MTTR** — incident resolved_at - incident started_at

Store these in a spreadsheet first. Graduate to dashboards when the habit sticks.

## Anti-patterns that hurt DORA

| Anti-pattern | Metric hurt |
|--------------|-------------|
| Deploying only on Fridays | Low deployment frequency, high batch size |
| No automated rollback | High MTTR |
| "Hotfix" without pipeline | High change failure rate |
| Ignoring staging observability | Surprises in production |

## Space framework (context)

DORA also discusses **culture** (Westrum), **architecture**, and **capabilities**. Observability is a technical capability that enables the rest.

## Exercise

For your current project, estimate:

1. How many production deploys last month?
2. How do you know a deploy failed?
3. How long did the last incident take to resolve?

Identify which of the four metrics is weakest — that's where to invest.

Next: [Rollback strategies](./06-rollback-strategies.md)
