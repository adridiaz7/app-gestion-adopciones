import type { Pool } from 'pg';
import { cargarConfiguracion } from '../../src/server/config/config.js';
import { crearPool } from '../../src/server/db/pool.js';

// Pool hacia adopciones_test. Las variables llegan de .env.test
// (vitest.config.ts las pone en process.env del proyecto "integration").
// Cada archivo de test crea el suyo en beforeAll y lo cierra en afterAll.
export function crearPoolDeTest(): Pool {
  return crearPool(cargarConfiguracion(process.env).bd);
}
