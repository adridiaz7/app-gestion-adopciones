// Rol del usuario en la API (RN-04). En la BD son ADOPTER, SHELTER y ADMIN
// (ver el glosario de database/README.md); el modelo traduce entre ambos.
export type Rol = 'ADOPTANTE' | 'PROTECTORA' | 'ADMINISTRADOR';

// Datos de un usuario que se pueden enviar al cliente. Nunca la fila completa:
// la contraseña (aunque sea su hash) no sale nunca del servidor.
export interface UsuarioPublico {
  id: number;
  email: string;
  rol: Rol;
  emailVerificado: boolean;
}
