import pg, { type PoolClient } from 'pg';
import type { Rol, UsuarioPublico } from '../../shared/usuario.js';
import { EmailYaRegistrado } from '../domain/errores.js';

type RolEnBd = 'ADOPTER' | 'SHELTER' | 'ADMIN';

// Glosario de database/README.md: rol de la API (español) ↔ ENUM user_role (inglés)
const ROL_EN_BD: Record<Rol, RolEnBd> = {
  ADOPTANTE: 'ADOPTER',
  PROTECTORA: 'SHELTER',
  ADMINISTRADOR: 'ADMIN',
};
const ROL_EN_API: Record<RolEnBd, Rol> = {
  ADOPTER: 'ADOPTANTE',
  SHELTER: 'PROTECTORA',
  ADMIN: 'ADMINISTRADOR',
};

interface FilaUsuario {
  id: number;
  email: string;
  role: RolEnBd;
  email_verified: boolean;
}

export interface DatosNuevoUsuario {
  email: string;
  hashContrasena: string;
  rol: Rol;
}

// Convierte la fila en los datos públicos del usuario. Es el ÚNICO sitio que
// construye un UsuarioPublico: así la contraseña nunca puede colarse en una
// respuesta (ni siquiera se lee de la BD: el RETURNING no la incluye).
function usuarioPublico(fila: FilaUsuario): UsuarioPublico {
  return {
    id: fila.id,
    email: fila.email,
    rol: ROL_EN_API[fila.role],
    emailVerificado: fila.email_verified,
  };
}

// Recibe un cliente (no el pool) porque se usa dentro de una transacción.
export async function insertarUsuario(
  cliente: PoolClient,
  datos: DatosNuevoUsuario,
): Promise<UsuarioPublico> {
  try {
    const resultado = await cliente.query<FilaUsuario>(
      `INSERT INTO app_user (email, password, role)
       VALUES ($1, $2, $3)
       RETURNING id, email, role, email_verified`,
      [datos.email, datos.hashContrasena, ROL_EN_BD[datos.rol]],
    );
    const fila = resultado.rows[0];
    if (fila === undefined) {
      throw new Error('INSERT … RETURNING no devolvió ninguna fila');
    }
    return usuarioPublico(fila);
  } catch (error) {
    // RN-06: el email único lo garantiza el índice uq_app_user_email (sobre
    // lower(email)). No se comprueba antes con un SELECT: entre el SELECT y el
    // INSERT podría registrarse otra persona con el mismo email (condición de
    // carrera). La BD es la única que puede decidirlo sin huecos.
    // 23505 = violación de unicidad (código estándar de PostgreSQL).
    if (
      error instanceof pg.DatabaseError &&
      error.code === '23505' &&
      error.constraint === 'uq_app_user_email'
    ) {
      throw new EmailYaRegistrado();
    }
    throw error;
  }
}
