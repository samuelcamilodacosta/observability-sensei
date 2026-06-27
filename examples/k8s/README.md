# Kubernetes example

Minimal Deployment + Service for the sample API with **liveness** and **readiness** probes on `/health`.

## Apply

```bash
# Build and load image locally (example with kind)
docker build -t observability-sensei-api:latest examples/node-api
kind load docker-image observability-sensei-api:latest

kubectl apply -f examples/k8s/
kubectl rollout status deployment/observability-sensei-api
```

## Probes

Both probes hit `GET /health`:

| Probe | Purpose |
|-------|---------|
| `livenessProbe` | Restart pod if process is stuck |
| `readinessProbe` | Remove pod from Service endpoints if degraded |

When error rate exceeds `HEALTH_MAX_ERROR_RATE` (default 5%), `/health` returns **503** and readiness fails — traffic stops without killing the pod.

## CI/CD integration

After `kubectl apply`, run the same scripts from your pipeline:

```bash
./examples/scripts/health-check.sh http://your-ingress/health
VERIFY_MODE=prometheus PROMETHEUS_URL=http://prometheus:9090 ./examples/scripts/verify-metrics.sh
./examples/scripts/production-gate.sh
```

See [canary mock](../scripts/canary-mock.sh) for gradual rollout pattern.
