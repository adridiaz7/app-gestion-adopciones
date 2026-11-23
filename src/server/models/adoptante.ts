import pg, { type PoolClient } from 'pg';
import { ProvinciaNoValida } from '../domain/errores.js';

export interface DatosNuevoAdoptante {
  nombre: string;
  apellidos: string;
  telefono: string;
  fechaNacimiento: string; // AAAA-MM-DD
  idProvincia: number;
  localidad: string;
}

// Perfil del adoptante (1:1 con app_user). Los datos del hogar se quedan a
// NULL: son opcionales al registrarse (RN-27).
export async function insertarAdoptante(
  cliente: PoolClient,
  idUsuario: number,
  datos: DatosNuevoAdoptante,
): Promise<void> {
  try {
    await cliente.query(
      `INSERT INTO adopter (id_user, first_name, last_name, phone, birth_date, id_province, city)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [
        idUsuario,
        datos.nombre,
        datos.apellidos,
        datos.telefono,
        datos.fechaNacimiento,
        datos.idProvincia, // RN-26: provincia del catálogo…
        datos.localidad, // …y localidad en texto
      ],
    );
  } catch (error) {
    // RN-26: que la provincia exista lo garantiza la FK hacia province.
    // 23503 = violación de clave foránea.
    if (
      error instanceof pg.DatabaseError &&
      error.code === '23503' &&
      error.constraint === 'adopter_id_province_fkey'
    ) {
      throw new ProvinciaNoValida();
    }
    throw error;
  }
}
