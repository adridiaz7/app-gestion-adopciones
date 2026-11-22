import type { Pool } from 'pg';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { crearApp } from '../../src/server/app.js';
import type { Provincia } from '../../src/shared/provincia.js';
import { crearPoolDeTest } from '../helpers/bd.js';

describe('Catálogo de provincias · GET /api/provincias (CU-01, CU-02, CU-13)', () => {
  let pool: Pool;

  beforeAll(() => {
    pool = crearPoolDeTest();
  });

  afterAll(async () => {
    await pool.end();
  });

  async function pedirProvincias(): Promise<{ status: number; provincias: Provincia[] }> {
    const respuesta = await request(crearApp(pool)).get('/api/provincias');
    return { status: respuesta.status, provincias: respuesta.body as Provincia[] };
  }

  it('RN-21/RN-26: responde 200 con las 52 provincias', async () => {
    const { status, provincias } = await pedirProvincias();

    expect(status).toBe(200);
    expect(provincias).toHaveLength(52);
  });

  it('cada provincia tiene solo id (número) y nombre', async () => {
    const { provincias } = await pedirProvincias();

    expect(provincias).toContainEqual({ id: 28, nombre: 'Madrid' });
    for (const provincia of provincias) {
      expect(Object.keys(provincia).sort()).toEqual(['id', 'nombre']);
      expect(typeof provincia.id).toBe('number');
    }
  });

  it('están en orden alfabético español, de principio a fin', async () => {
    const { provincias } = await pedirProvincias();
    const nombres = provincias.map((provincia) => provincia.nombre);

    // Intl.Collator('es') ordena con las reglas del español: la tilde no
    // manda "Ávila" al final, como pasaría comparando códigos de carácter.
    const ordenEspanol = [...nombres].sort(new Intl.Collator('es').compare);
    expect(nombres).toEqual(ordenEspanol);
  });

  it('ejemplo concreto: "Ávila" va justo entre "Asturias" y "Badajoz"', async () => {
    const { provincias } = await pedirProvincias();
    const nombres = provincias.map((provincia) => provincia.nombre);

    const posicion = nombres.indexOf('Ávila');
    // Si Ávila no viniera, indexOf daría -1: se comprueba antes de usar la posición
    expect(posicion).toBeGreaterThan(0);
    expect(nombres.slice(posicion - 1, posicion + 2)).toEqual(['Asturias', 'Ávila', 'Badajoz']);
  });
});
