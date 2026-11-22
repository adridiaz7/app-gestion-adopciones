import pg from 'pg';
import type { ConfiguracionBd } from '../config/config.js';

// Un pool es un grupo de conexiones abiertas que se reutilizan: abrir una
// conexión nueva por cada petición sería lento. Se crea una sola vez
// (en server.ts, o en cada test) y se pasa a quien lo necesite (inyección).
export function crearPool(configuracion: ConfiguracionBd): pg.Pool {
  const pool = new pg.Pool({
    host: configuracion.host,
    port: configuracion.puerto,
    database: configuracion.nombre,
    user: configuracion.usuario,
    password: configuracion.contrasena,
  });

  // Si PostgreSQL corta una conexión que estaba en reposo (por ejemplo, al
  // reiniciarse), el pool emite 'error'. En Node, un 'error' sin nadie que lo
  // escuche tumba el proceso entero. Se registra y el pool la descarta: la
  // próxima consulta abrirá una conexión nueva.
  pool.on('error', (error) => {
    console.error('Error en una conexión inactiva del pool:', error);
  });

  return pool;
}
