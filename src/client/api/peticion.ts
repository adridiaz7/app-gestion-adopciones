import type { RespuestaDeError } from '../../shared/error.js';

// Resultado de una llamada a la API: o los datos, o el error con el formato
// común { codigo, mensaje }. Así cada pantalla decide qué hacer sin try/catch.
export type Resultado<T> =
  | { ok: true; datos: T }
  | { ok: false; error: RespuestaDeError['error'] };

// Error para cuando ni siquiera llega una respuesta de la API (sin conexión,
// servidor apagado, respuesta que no es JSON…).
const ERROR_DE_CONEXION: RespuestaDeError['error'] = {
  codigo: 'SIN_CONEXION',
  mensaje: 'No se ha podido conectar con el servidor. Inténtalo de nuevo.',
};

// fetch hacia nuestra propia API. Página y API están en el mismo origen, así
// que el navegador enviará la cookie de sesión sin configurar nada (CU-04).
export async function pedirApi<T>(ruta: string, opciones: RequestInit = {}): Promise<Resultado<T>> {
  try {
    const respuesta = await fetch(ruta, {
      ...opciones,
      headers: { 'Content-Type': 'application/json', ...opciones.headers },
    });
    const cuerpo: unknown = await respuesta.json();
    if (respuesta.ok) {
      return { ok: true, datos: cuerpo as T };
    }
    return { ok: false, error: (cuerpo as RespuestaDeError).error };
  } catch {
    return { ok: false, error: ERROR_DE_CONEXION };
  }
}
