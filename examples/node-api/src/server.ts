import './telemetry';

import { logger } from './logger';
import app from './app';

const PORT = parseInt(process.env.PORT ?? '3000', 10);

const server = app.listen(PORT, () => {
  logger.info({ port: PORT }, 'server started');
});

function shutdown(signal: string): void {
  logger.info({ signal }, 'shutdown signal received');
  server.close(() => {
    logger.info('server closed');
    process.exit(0);
  });

  setTimeout(() => {
    logger.error('forced shutdown after timeout');
    process.exit(1);
  }, 10_000).unref();
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
