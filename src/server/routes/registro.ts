import { Router } from 'express';
import type { Pool } from 'pg';
import type { EnviadorEmail } from '../auth/enviador-email.js';
import { registrarAdoptante } from '../controllers/registro.js';
import type { Reloj } from '../domain/reloj.js';

// Un endpoint por rol: cada uno recibe datos distintos y fija su propio rol
// (CU-01 adoptante; CU-02 protectora llegará aquí).
export function crearRutasRegistro(
  pool: Pool,
  reloj: Reloj,
  enviadorEmail: EnviadorEmail,
  urlPublica: string,
): Router {
  const router = Router();
  router.post(
    '/api/registro/adoptante',
    registrarAdoptante(pool, reloj, enviadorEmail, urlPublica),
  );
  return router;
}
