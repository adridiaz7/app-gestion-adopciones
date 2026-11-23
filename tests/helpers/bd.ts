import type { Pool } from 'pg';
import { cargarConfiguracion } from '../../src/server/config/config.js';
import { crearPool } from '../../src/server/db/pool.js';

// Pool hacia adopciones_test. Las variables llegan de .env.test
// (vitest.config.ts las pone en process.env del proyecto "integration").
// Cada archivo de test crea el suyo en beforeAll y lo cierra en afterAll.
export function crearPoolDeTest(): Pool {
  return crearPool(cargarConfiguracion(process.env).bd);
}

// Deja la BD sin los usuarios que crean los tests, para que cada test empiece
// igual (ver TECH_SPEC, "Base de datos de los tests").
// No se usa TRUNCATE en app_user porque se llevaría también al administrador
// que carga seed.sql: se borra todo menos el ADMIN. El orden importa: primero
// las tablas que apuntan a app_user, después los usuarios.
export async function vaciarUsuariosDePrueba(pool: Pool): Promise<void> {
  await pool.query('DELETE FROM auth_token');
  await pool.query('DELETE FROM session');
  await pool.query('DELETE FROM adopter');
  await pool.query("DELETE FROM app_user WHERE role <> 'ADMIN'");
}
