import type { ErrorRequestHandler, RequestHandler } from 'express';
import type { RespuestaDeError } from '../../shared/error.js';
import {
  Conflicto,
  DatosNoValidos,
  ErrorDeNegocio,
  ErrorDeValidacion,
} from '../domain/errores.js';

// Categoría de error de negocio → código HTTP (ver TECH_SPEC, "Errores").
// Es el único sitio del código que sabe de HTTP y de categorías a la vez.
function estadoHttp(error: ErrorDeNegocio): number {
  if (error instanceof ErrorDeValidacion) return 400;
  if (error instanceof Conflicto) return 409;
  // Una categoría nueva sin traducir aquí es un fallo de programación
  return 500;
}

// express.json() lanza errores con un `type` ('entity.parse.failed' si el
// JSON está mal formado, 'entity.too.large' si pasa de 100 KB…) y un `status`
// 4xx: el fallo es del cliente, no del servidor. Devuelve ese status, o null
// si el error no viene de leer el cuerpo.
function estadoErrorDelCuerpo(error: unknown): number | null {
  if (
    typeof error === 'object' &&
    error !== null &&
    'type' in error &&
    typeof error.type === 'string' &&
    error.type.startsWith('entity.') &&
    'status' in error &&
    typeof error.status === 'number' &&
    error.status >= 400 &&
    error.status < 500
  ) {
    return error.status;
  }
  return null;
}

function responderError(res: Parameters<RequestHandler>[1], estado: number, error: ErrorDeNegocio) {
  const respuesta: RespuestaDeError = {
    error: { codigo: error.codigo, mensaje: error.message },
  };
  res.status(estado).json(respuesta);
}

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
// Express reconoce un manejador de errores porque declara 4 parámetros.
export const manejarErrores: ErrorRequestHandler = (error, _req, res, next) => {
  // Si la respuesta ya había empezado a enviarse, no se puede cambiar el
  // status ni mandar otro cuerpo. Se le pasa a Express, que cierra la conexión.
  if (res.headersSent) {
    console.error(error);
    next(error);
    return;
  }

  // Errores previstos: no son fallos del servidor, así que no se registran
  // en la consola. Se responden con su categoría y su texto.
  if (error instanceof ErrorDeNegocio) {
    responderError(res, estadoHttp(error), error);
    return;
  }
  const estadoCuerpo = estadoErrorDelCuerpo(error);
  if (estadoCuerpo !== null) {
    responderError(res, estadoCuerpo, new DatosNoValidos());
    return;
  }

  // Cualquier otro error es inesperado (500).
  // El detalle se queda en el servidor, para quien tenga que depurarlo...
  console.error(error);

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
