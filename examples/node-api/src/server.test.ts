import { describe, it, expect } from 'vitest';
import request from 'supertest';
import app from './app';

describe('observability-sensei API', () => {
  it('GET /health returns ok status', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body).toHaveProperty('version');
    expect(res.body.checks).toHaveProperty('memory');
  });

  it('GET /api/example returns success payload', async () => {
    const res = await request(app).get('/api/example');
    expect(res.status).toBe(200);
    expect(res.body.message).toContain('observability-sensei');
    expect(res.body).toHaveProperty('latencyMs');
  });

  it('GET /api/example/error returns 500', async () => {
    const res = await request(app).get('/api/example/error');
    expect(res.status).toBe(500);
    expect(res.body.error).toBeDefined();
  });

  it('GET /metrics exposes Prometheus format', async () => {
    await request(app).get('/api/example');
    const res = await request(app).get('/metrics');
    expect(res.status).toBe(200);
    expect(res.text).toContain('http_requests_total');
  });

  it('GET /unknown returns 404', async () => {
    const res = await request(app).get('/unknown-route');
    expect(res.status).toBe(404);
  });

  it('does not double-count error metrics', async () => {
    const beforeRes = await request(app).get('/metrics');
    const countErrors = (text: string) => {
      const lines = text.match(/^http_request_errors_total[^\n]*/gm) ?? [];
      return lines.reduce((acc, line) => acc + parseFloat(line.split(/\s+/).pop() ?? '0'), 0);
    };
    const before = countErrors(beforeRes.text);

    await request(app).get('/api/example/error');

    const afterRes = await request(app).get('/metrics');
    const after = countErrors(afterRes.text);
    expect(after - before).toBe(1);
  });

  it('GET /health returns degraded when error rate exceeds threshold', async () => {
    for (let i = 0; i < 10; i++) {
      await request(app).get('/api/example/error');
    }
    const res = await request(app).get('/health');
    expect(res.status).toBe(503);
    expect(res.body.status).toBe('degraded');
    expect(res.body.checks.error_rate).toBe('degraded');
  });
});
