// Forma común de todas las respuestas de error de la API (ver TECH_SPEC, "Errores").
// codigo: constante para el programa (el frontend decide según el código).
// mensaje: texto en español para la persona.
export interface RespuestaDeError {
  error: {
    codigo: string;
    mensaje: string;
  };
}
