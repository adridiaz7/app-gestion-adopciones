import { afterEach, describe, expect, it, vi } from 'vitest';
import { crearPool } from '../../src/server/db/pool.js';

// crearPool no abre ninguna conexión hasta la primera consulta,
// así que este test no necesita la BD.
const configuracion = {
  host: 'localhost',
  puerto: 5432,
  nombre: 'cualquiera',
  usuario: 'cualquiera',
  contrasena: 'cualquiera',
};

describe('Pool de conexiones', () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('si se cae una conexión en reposo, lo registra y el proceso sigue vivo', async () => {
    const registro = vi.spyOn(console, 'error').mockImplementation(() => undefined);
    const pool = crearPool(configuracion);

    // Así avisa pg.Pool cuando PostgreSQL corta una conexión que no se estaba usando.
    // Sin nadie escuchando 'error', emit lanzaría una excepción y Node terminaría.
    expect(() => pool.emit('error', new Error('el servidor cerró la conexión'))).not.toThrow();
    expect(registro).toHaveBeenCalled();

    await pool.end();
  });
});
