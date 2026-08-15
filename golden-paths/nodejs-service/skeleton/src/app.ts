import express from 'express';
import pinoHttp from 'pino-http';
import { collectDefaultMetrics, register } from 'prom-client';

import { logger } from './logger.js';

collectDefaultMetrics();

export function createApp() {
  const app = express();

  app.use(pinoHttp({ logger }));
  app.use(express.json({ limit: '1mb' }));

  app.get('/healthz', (_req, res) => {
    res.json({ status: 'ok' });
  });

  // Kubernetes readiness probe — separate from liveness so a warming instance
  // is not restarted, only kept out of the load balancer.
  app.get('/readyz', (_req, res) => {
    res.json({ status: 'ready' });
  });

  app.get('/metrics', async (_req, res) => {
    res.set('Content-Type', register.contentType);
    res.send(await register.metrics());
  });

  app.get('/', (_req, res) => {
    res.json({ service: '${{ values.name }}', description: '${{ values.description }}' });
  });

  return app;
}
