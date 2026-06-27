import { Router, Request, Response } from 'express';
import { trace, SpanStatusCode } from '@opentelemetry/api';
import { getServiceVersion } from '../logger';
import { getMetricsSnapshot } from '../metrics';

const router = Router();
const tracer = trace.getTracer('observability-sensei-api');

interface HealthResponse {
  status: 'ok' | 'degraded' | 'unhealthy';
  uptime: number;
  version: string;
  timestamp: string;
  checks: Record<string, string>;
}

router.get('/', async (_req: Request, res: Response) => {
  const span = tracer.startSpan('health.check');

  try {
    const memoryUsage = process.memoryUsage();
    const heapUsedMb = memoryUsage.heapUsed / 1024 / 1024;
    const memoryOk = heapUsedMb < 512;

    const metrics = await getMetricsSnapshot();
    const maxErrorRate = parseFloat(process.env.HEALTH_MAX_ERROR_RATE ?? '0.05');
    const errorRateOk = metrics.errorRate < maxErrorRate;

    const checks: Record<string, string> = {
      memory: memoryOk ? 'ok' : 'degraded',
      dependencies: 'ok',
      error_rate: errorRateOk ? 'ok' : 'degraded',
    };

    const allOk = Object.values(checks).every((c) => c === 'ok');

    const body: HealthResponse = {
      status: allOk ? 'ok' : 'degraded',
      uptime: process.uptime(),
      version: getServiceVersion(),
      timestamp: new Date().toISOString(),
      checks,
    };

    span.setAttribute('health.status', body.status);
    res.status(allOk ? 200 : 503).json(body);
  } catch (error) {
    span.recordException(error as Error);
    span.setStatus({ code: SpanStatusCode.ERROR });
    res.status(503).json({
      status: 'unhealthy',
      uptime: process.uptime(),
      version: getServiceVersion(),
      timestamp: new Date().toISOString(),
      checks: { internal: 'failed' },
    });
  } finally {
    span.end();
  }
});

export default router;
