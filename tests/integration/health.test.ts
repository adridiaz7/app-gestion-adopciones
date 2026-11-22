import request from 'supertest';
import { describe, expect, it } from 'vitest';
import { crearApp } from '../../src/server/app.js';

describe('GET /api/health', () => {
  it('responde 200 con { estado: "ok" }', async () => {
    const app = crearApp();

    const respuesta = await request(app).get('/api/health');

    expect(respuesta.status).toBe(200);
    expect(respuesta.body).toEqual({ estado: 'ok' });
  });
});
