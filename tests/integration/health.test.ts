import type { Pool } from 'pg';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { crearApp } from '../../src/server/app.js';
import { crearPoolDeTest } from '../helpers/bd.js';

describe('GET /api/health', () => {
  let pool: Pool;

  beforeAll(() => {
    pool = crearPoolDeTest();
  });

  afterAll(async () => {
    await pool.end();
  });

  it('responde 200 con { estado: "ok" }', async () => {
    const app = crearApp(pool);

    const respuesta = await request(app).get('/api/health');

    expect(respuesta.status).toBe(200);
    expect(respuesta.body).toEqual({ estado: 'ok' });
  });
});
