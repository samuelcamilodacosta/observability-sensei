import pino from 'pino';

const serviceVersion = process.env.SERVICE_VERSION ?? '1.0.0';

export const logger = pino({
  level: process.env.LOG_LEVEL ?? 'info',
  base: {
    service: 'observability-sensei-api',
    version: serviceVersion,
    environment: process.env.NODE_ENV ?? 'development',
  },
  formatters: {
    level: (label) => ({ level: label }),
  },
  timestamp: pino.stdTimeFunctions.isoTime,
});

export function getServiceVersion(): string {
  return serviceVersion;
}
