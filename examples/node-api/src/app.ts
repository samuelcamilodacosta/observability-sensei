import express from 'express';
import pinoHttp from 'pino-http';
import { randomUUID } from 'crypto';
import { logger } from './logger';
import { register } from './metrics';
import healthRouter from './routes/health';
import exampleRouter, { recordExampleMetrics } from './routes/example';

const app = express();

app.use(express.json());

app.use(
  pinoHttp({
    logger,
    genReqId: (req) =>
      (req.headers['x-request-id'] as string) ?? randomUUID(),
    customProps: (req) => ({
      requestId: req.id,
    }),
  }),
);

app.use((req, res, next) => {
  const start = process.hrtime.bigint();

  res.on('finish', () => {
    const durationNs = process.hrtime.bigint() - start;
    const durationSeconds = Number(durationNs) / 1e9;
    const route = req.route?.path
      ? `${req.baseUrl}${req.route.path}`
      : req.path;

    if (route !== '/metrics' && route !== '/health' && route !== '/health/') {
      recordExampleMetrics(req.method, route, res.statusCode, durationSeconds);
    }
  });

  next();
});

app.get('/metrics', async (_req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

app.use('/health', healthRouter);
app.use('/api/example', exampleRouter);

app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' });
});

app.use(
  (
    err: Error,
    req: express.Request,
    res: express.Response,
    _next: express.NextFunction,
  ) => {
    req.log.error({ err }, 'unhandled error');
    res.status(500).json({ error: 'Internal server error' });
  },
);

export default app;
