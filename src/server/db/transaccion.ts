import type { Pool, PoolClient } from 'pg';

// RN-171: las operaciones que cambian varias cosas a la vez van en UNA
// transacción: o se aplican todos los cambios o ninguno.
//
// Una transacción vive en UNA conexión. Por eso no basta con pool.query (cada
// llamada puede ir por una conexión distinta del pool): se pide una conexión
// (cliente), todo el trabajo se hace con ella y al final se devuelve al pool.
//
// Pendiente para CU-04: cuando haya usuario con sesión, aquí se fijará
// app.current_user_id para la auditoría (ver CLAUDE.md, "Auditoría"). Hoy el
// registro lo hace un visitante, que aún no es usuario: queda como "sistema".
export async function conTransaccion<T>(
  pool: Pool,
  trabajo: (cliente: PoolClient) => Promise<T>,
): Promise<T> {
  const cliente = await pool.connect();
  // Si la conexión queda en mal estado, se pasa este error a release() para
  // que pg la destruya en vez de devolverla al pool.
  let conexionRota: Error | undefined;
  try {
    await cliente.query('BEGIN');
    const resultado = await trabajo(cliente);
    await cliente.query('COMMIT');
    return resultado;
  } catch (error) {
    // Cualquier fallo deshace TODO lo hecho dentro de la transacción
    try {
      await cliente.query('ROLLBACK');
    } catch (errorRollback) {
      // El ROLLBACK también ha fallado (por ejemplo, se cayó la conexión).
      // No se lanza este error: taparía el original, que es el que explica
      // qué pasó. La conexión se marca para descartarla.
      conexionRota = errorRollback instanceof Error ? errorRollback : new Error(String(errorRollback));
    }
    throw error;
  } finally {
    // Pase lo que pase, la conexión vuelve al pool (si no, se agotarían)…
    // …salvo que esté rota: entonces release(error) la destruye.
    cliente.release(conexionRota);
  }
}
