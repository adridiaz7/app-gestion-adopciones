import type { Pool } from 'pg';
import type { Provincia } from '../../shared/provincia.js';

// Fila tal como la devuelve PostgreSQL (nombres de la BD, en inglés).
// pg convierte smallint en number, así que id ya llega como número.
interface FilaProvincia {
  id: number;
  name: string;
}

// RN-21 / RN-26: catálogo de provincias para la ubicación de protectoras y adoptantes.
// COLLATE "es-x-icu" fija el orden alfabético español en la propia consulta
// ("Ávila" entre "Asturias" y "Badajoz"), sin depender de cómo se creó la BD.
export async function listarProvincias(pool: Pool): Promise<Provincia[]> {
  const resultado = await pool.query<FilaProvincia>(
    'SELECT id, name FROM province ORDER BY name COLLATE "es-x-icu"',
  );
  return resultado.rows.map((fila) => ({ id: fila.id, nombre: fila.name }));
}
