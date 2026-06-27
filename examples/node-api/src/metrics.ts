import { Registry, Counter, Histogram, collectDefaultMetrics } from 'prom-client';

export const register = new Registry();

collectDefaultMetrics({ register, prefix: 'nodejs_' });

export const httpRequestsTotal = new Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'] as const,
  registers: [register],
});

export const httpRequestErrorsTotal = new Counter({
  name: 'http_request_errors_total',
  help: 'Total number of HTTP request errors (5xx and simulated errors)',
  labelNames: ['route'] as const,
  registers: [register],
});

export const httpRequestDurationSeconds = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'route'] as const,
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
  registers: [register],
});

// Simulated latency gauge for Production Gate demos (updated per request)
export const simulatedP99LatencyMs = new Histogram({
  name: 'http_simulated_latency_ms',
  help: 'Simulated request latency in ms for gate validation demos',
  labelNames: ['route'] as const,
  buckets: [10, 25, 50, 100, 250, 500, 1000, 2000],
  registers: [register],
});

export async function getMetricsSnapshot(): Promise<{
  totalRequests: number;
  totalErrors: number;
  errorRate: number;
}> {
  const metrics = await register.getMetricsAsJSON();
  let totalRequests = 0;
  let totalErrors = 0;

  for (const metric of metrics) {
    if (metric.name === 'http_requests_total') {
      for (const v of metric.values ?? []) {
        totalRequests += v.value ?? 0;
      }
    }
    if (metric.name === 'http_request_errors_total') {
      for (const v of metric.values ?? []) {
        totalErrors += v.value ?? 0;
      }
    }
  }

  const errorRate = totalRequests > 0 ? totalErrors / totalRequests : 0;

  return { totalRequests, totalErrors, errorRate };
}
