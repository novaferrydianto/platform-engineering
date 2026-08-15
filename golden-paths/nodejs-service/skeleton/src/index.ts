import { createApp } from './app.js';
import { logger } from './logger.js';

const port = Number(process.env.PORT ?? 8080);
const server = createApp().listen(port, () => {
  logger.info({ port }, 'service listening');
});

for (const signal of ['SIGTERM', 'SIGINT'] as const) {
  process.on(signal, () => {
    logger.info({ signal }, 'shutting down');
    server.close(() => process.exit(0));
  });
}
