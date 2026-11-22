import type { ErrorRequestHandler, RequestHandler } from 'express';
import type { RespuestaDeError } from '../../shared/error.js';

// Se monta en /api después de todas las rutas: si una petición llega hasta
// aquí es que ninguna ruta la ha atendido. Sin esto, Express respondería con
// su página HTML "Cannot GET …", rompiendo el formato común de errores.
export const rutaNoEncontrada: RequestHandler = (_req, res) => {
  const respuesta: RespuestaDeError = {
    error: {
      codigo: 'RUTA_NO_ENCONTRADA',
      mensaje: 'La ruta solicitada no existe.',
    },
  };
  res.status(404).json(respuesta);
};

// Último eslabón de la cadena de Express: recibe cualquier error que no se
// haya atendido antes (incluidas las promesas rechazadas de los controladores
// async, que Express 5 reenvía aquí por sí solo).
//
// Por ahora solo hay errores inesperados → 500. Cuando aparezca el primer
// error de negocio, aquí se traducirá cada categoría a su código HTTP
// (ErrorDeValidacion → 400, NoEncontrado → 404…; ver TECH_SPEC).
//
// Express reconoce un manejador de errores porque declara 4 parámetros.
export const manejarErrores: ErrorRequestHandler = (error, _req, res, next) => {
  // El detalle se queda en el servidor, para quien tenga que depurarlo...
  console.error(error);

  // Si la respuesta ya había empezado a enviarse, no se puede cambiar el
  // status ni mandar otro cuerpo. Se le pasa a Express, que cierra la conexión.
  if (res.headersSent) {
    next(error);
    return;
  }

  // ...y al cliente solo le llega un mensaje genérico: la traza o el texto
  // de un error de SQL pueden revelar cómo está hecho el sistema por dentro.
  const respuesta: RespuestaDeError = {
    error: {
      codigo: 'ERROR_INTERNO',
      mensaje: 'Ha ocurrido un error inesperado. Inténtalo de nuevo más tarde.',
    },
  };
  res.status(500).json(respuesta);
};
