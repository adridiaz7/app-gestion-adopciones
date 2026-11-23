import type { UsuarioPublico } from './usuario.js';

// Cuerpo de POST /api/registro/adoptante (CU-01).
// El rol no viaja aquí: lo fija el endpoint, para que el cliente no pueda elegirlo.
export interface DatosRegistroAdoptante {
  email: string;
  contrasena: string;
  nombre: string;
  apellidos: string;
  telefono: string;
  fechaNacimiento: string; // AAAA-MM-DD
  idProvincia: number;
  localidad: string;
}

// Respuesta 201 del registro.
export interface RespuestaRegistro {
  usuario: UsuarioPublico;
}
