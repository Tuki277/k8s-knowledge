// OpenTelemetry bootstrap - phải được load TRƯỚC server.js:
//   node --require ./instrumentation.js server.js
require('dotenv').config();

// Gửi metrics + logs; muốn bật traces thì set OTEL_TRACES_EXPORTER=otlp
process.env.OTEL_SERVICE_NAME ??= 'todo-backend';
process.env.OTEL_TRACES_EXPORTER ??= 'none';

const { NodeSDK } = require('@opentelemetry/sdk-node');
const { PeriodicExportingMetricReader } = require('@opentelemetry/sdk-metrics');
const { OTLPMetricExporter } = require('@opentelemetry/exporter-metrics-otlp-http');
const { BatchLogRecordProcessor } = require('@opentelemetry/sdk-logs');
const { OTLPLogExporter } = require('@opentelemetry/exporter-logs-otlp-http');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { HostMetrics } = require('@opentelemetry/host-metrics');
const { metrics } = require('@opentelemetry/api');

// Endpoint đọc từ OTEL_EXPORTER_OTLP_ENDPOINT (vd: http://signoz-otel-collector.signoz.svc.cluster.local:4318)
const metricReader = new PeriodicExportingMetricReader({
  exporter: new OTLPMetricExporter(),
  exportIntervalMillis: Number(process.env.OTEL_METRIC_EXPORT_INTERVAL) || 15000
});

const sdk = new NodeSDK({
  metricReaders: [metricReader],
  // Logs của pino được instrumentation-pino chuyển sang OTel và gửi về /v1/logs
  logRecordProcessors: [new BatchLogRecordProcessor({ exporter: new OTLPLogExporter() })],
  instrumentations: [
    // http/express/pg/redis metrics + runtime metrics (event loop, GC, heap) + pino logs
    getNodeAutoInstrumentations({
      '@opentelemetry/instrumentation-fs': { enabled: false },
      '@opentelemetry/instrumentation-dns': { enabled: false },
      '@opentelemetry/instrumentation-net': { enabled: false }
    })
  ]
});

sdk.start();

// CPU, memory, network của process/host
new HostMetrics({ meterProvider: metrics.getMeterProvider(), name: 'todo-backend-host-metrics' }).start();

const shutdown = () => {
  sdk.shutdown()
    .catch((err) => console.error('Error shutting down OpenTelemetry', err))
    .finally(() => process.exit(0));
};
process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
