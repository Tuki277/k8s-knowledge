const pino = require('pino');
const pinoHttp = require('pino-http');

// Log JSON ra stdout (kubectl logs) và đồng thời được gửi về SigNoz qua OTLP (xem instrumentation.js)
const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  base: { service: process.env.OTEL_SERVICE_NAME || 'todo-backend' },
  redact: ['req.headers.authorization', 'req.headers.cookie']
});

// Access log cho mỗi request, bỏ qua readiness/liveness probe để tránh spam
const httpLogger = pinoHttp({
  logger,
  autoLogging: {
    ignore: (req) => (req.headers['user-agent'] || '').startsWith('kube-probe')
  },
  customLogLevel: (req, res, err) => {
    if (err || res.statusCode >= 500) return 'error';
    if (res.statusCode >= 400) return 'warn';
    return 'info';
  },
  customSuccessMessage: (req, res, responseTime) =>
    `${req.method} ${req.url} ${res.statusCode} - ${responseTime}ms`,
  customErrorMessage: (req, res, err) =>
    `${req.method} ${req.url} ${res.statusCode} - ${err.message}`,
  serializers: {
    req: (req) => ({ method: req.method, url: req.url, remoteAddress: req.remoteAddress }),
    res: (res) => ({ statusCode: res.statusCode })
  }
});

module.exports = { logger, httpLogger };
