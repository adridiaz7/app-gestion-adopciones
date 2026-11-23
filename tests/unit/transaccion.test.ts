import type { Pool, PoolClient } from 'pg';
import { describe, expect, it, vi } from 'vitest';
import { conTransaccion } from '../../src/server/db/transaccion.js';

// Doble de prueba del pool: solo imita connect(), y el cliente que devuelve solo
// imita query() y release(), que es todo lo que usa conTransaccion.
// Simula una conexión que se rompe: el propio ROLLBACK también falla.
function poolConRollbackQueFalla() {
  const release = vi.fn();
  const cliente = {
    query: vi.fn((sql: string) =>
      sql === 'ROLLBACK' ? Promise.reject(new Error('conexión perdida')) : Promise.resolve(),
    ),
    release,
  } as unknown as PoolClient;
  const pool = { connect: () => Promise.resolve(cliente) } as unknown as Pool;
  return { pool, release };
}

describe('Transacciones (RN-171)', () => {
  it('si el ROLLBACK también falla, se propaga el error original, no el del ROLLBACK', async () => {
    const { pool } = poolConRollbackQueFalla();
    const original = new Error('fallo del trabajo');

    await expect(conTransaccion(pool, () => Promise.reject(original))).rejects.toBe(original);
  });

  it('si el ROLLBACK falla, la conexión se descarta en vez de volver al pool', async () => {
    const { pool, release } = poolConRollbackQueFalla();

    await conTransaccion(pool, () => Promise.reject(new Error('fallo'))).catch(() => undefined);

    // release(error) le dice a pg que destruya esa conexión: estaría en un estado desconocido
    expect(release).toHaveBeenCalledWith(expect.any(Error));
  });
});
