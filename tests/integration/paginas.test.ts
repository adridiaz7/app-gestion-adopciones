import type { Pool } from 'pg';
import request from 'supertest';
import { describe, expect, it } from 'vitest';
import { crearApp } from '../../src/server/app.js';

// Doble de prueba vacío: servir archivos estáticos no consulta la BD, así que
// el pool no necesita imitar nada.
const poolSinUso = {} as Pool;

describe('Pantallas del registro · archivos estáticos (CU-01)', () => {
  it.each(['/registro.html', '/registro-adoptante.html', '/css/estilos.css'])(
    'sirve %s',
    async (ruta) => {
      const respuesta = await request(crearApp(poolSinUso)).get(ruta);

      expect(respuesta.status).toBe(200);
    },
  );

  it('una URL fuera de /api que no existe no responde con el JSON de la API', async () => {
    const respuesta = await request(crearApp(poolSinUso)).get('/no-existe.html');

    expect(respuesta.status).toBe(404);
    expect(respuesta.headers['content-type']).not.toMatch(/json/);
  });
});
