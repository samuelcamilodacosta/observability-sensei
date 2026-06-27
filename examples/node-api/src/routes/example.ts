import { Router, Request, Response, NextFunction } from 'express';
import { trace, SpanStatusCode } from '@opentelemetry/api';
import {
  httpRequestsTotal,
  httpRequestErrorsTotal,
  httpRequestDurationSeconds,
  simulatedP99LatencyMs,
} from '../metrics';

const router = Router();
const tracer = trace.getTracer('observability-sensei-api');

function simulateDbCall(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

router.get('/', async (req: Request, res: Response, next: NextFunction) => {
  const span = tracer.startSpan('example.handler');
  const start = Date.now();

  try {
    span.setAttribute('http.route', '/api/example');
    await simulateDbCall(8 + Math.floor(Math.random() * 12));

    const durationMs = Date.now() - start;
    simulatedP99LatencyMs.observe({ route: '/api/example' }, durationMs);

    res.json({
      message: 'Hello from observability-sensei',
      requestId: req.headers['x-request-id'],
      latencyMs: durationMs,
    });
  } catch (error) {
    span.recordException(error as Error);
    span.setStatus({ code: SpanStatusCode.ERROR });
    next(error);
  } finally {
    span.end();
  }
});

router.get('/error', (_req: Request, res: Response) => {
  const span = tracer.startSpan('example.error');
  const start = Date.now();

  try {
    span.setAttribute('http.route', '/api/example/error');
    span.setStatus({ code: SpanStatusCode.ERROR, message: 'Simulated error' });

    const durationMs = Date.now() - start;
    simulatedP99LatencyMs.observe({ route: '/api/example/error' }, durationMs);

    res.status(500).json({
      error: 'Simulated server error for observability testing',
      hint: 'Use this endpoint to test Production Gate error rate thresholds',
    });
  } finally {
    span.end();
  }
});

router.get('/slow', async (_req: Request, res: Response) => {
  const span = tracer.startSpan('example.slow');
  const delay = 600 + Math.floor(Math.random() * 200);

  try {
    await simulateDbCall(delay);
    simulatedP99LatencyMs.observe({ route: '/api/example/slow' }, delay);

    res.json({
      message: 'Slow response for latency gate testing',
      latencyMs: delay,
    });
  } finally {
    span.end();
  }
});

export function recordExampleMetrics(
  method: string,
  route: string,
  statusCode: number,
  durationSeconds: number,
): void {
  httpRequestsTotal.inc({
    method,
    route,
    status_code: String(statusCode),
  });
  httpRequestDurationSeconds.observe({ method, route }, durationSeconds);

  if (statusCode >= 500) {
    httpRequestErrorsTotal.inc({ route });
  }
}

export default router;
