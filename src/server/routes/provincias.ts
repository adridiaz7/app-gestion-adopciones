import { Router } from 'express';
import type { Pool } from 'pg';
import { obtenerProvincias } from '../controllers/provincias.js';

// URL + verbo HTTP → controlador.
export function crearRutasProvincias(pool: Pool): Router {
  const router = Router();
  router.get('/api/provincias', obtenerProvincias(pool));
  return router;
}
