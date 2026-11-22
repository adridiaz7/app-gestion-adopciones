import type { RequestHandler } from 'express';
import type { Pool } from 'pg';
import { listarProvincias } from '../models/provincia.js';

// El controlador recibe el pool desde fuera (inyección) y devuelve la función
// que atiende la petición. Express 5 captura por sí solo los errores de las
// funciones async, así que no hace falta try/catch.
export function obtenerProvincias(pool: Pool): RequestHandler {
  return async (_req, res) => {
    res.json(await listarProvincias(pool));
  };
}
