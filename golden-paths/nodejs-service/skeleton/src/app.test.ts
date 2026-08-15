import request from 'supertest';
import { describe, expect, it } from 'vitest';

import { createApp } from './app.js';

describe('${{ values.name }}', () => {
  const app = createApp();

  it('reports healthy', async () => {
    const res = await request(app).get('/healthz');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: 'ok' });
  });

  it('reports ready', async () => {
    const res = await request(app).get('/readyz');
    expect(res.status).toBe(200);
  });

  it('exposes prometheus metrics', async () => {
    const res = await request(app).get('/metrics');
    expect(res.status).toBe(200);
    expect(res.text).toContain('process_cpu_user_seconds_total');
  });
});
