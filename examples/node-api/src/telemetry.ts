import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { Resource } from '@opentelemetry/resources';
import {
  ATTR_SERVICE_NAME,
  ATTR_SERVICE_VERSION,
} from '@opentelemetry/semantic-conventions';

const serviceName = 'observability-sensei-api';
const serviceVersion = process.env.SERVICE_VERSION ?? '1.0.0';

const otlpEndpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT;

const traceExporter = otlpEndpoint
  ? new OTLPTraceExporter({ url: `${otlpEndpoint}/v1/traces` })
  : undefined;

const sdk = new NodeSDK({
  resource: new Resource({
    [ATTR_SERVICE_NAME]: serviceName,
    [ATTR_SERVICE_VERSION]: serviceVersion,
  }),
  traceExporter,
  instrumentations: [
    getNodeAutoInstrumentations({
      '@opentelemetry/instrumentation-fs': { enabled: false },
    }),
  ],
});

sdk.start();

if (!otlpEndpoint) {
  // eslint-disable-next-line no-console
  console.log(
    '[telemetry] OpenTelemetry initialized (auto-instrumentation). Set OTEL_EXPORTER_OTLP_ENDPOINT to export traces.',
  );
}

process.on('SIGTERM', () => {
  sdk.shutdown().catch(() => undefined);
});
