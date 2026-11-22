import express, { type Express } from 'express';
import type { Pool } from 'pg';
import { manejarErrores, rutaNoEncontrada } from './middlewares/errores.js';
import { crearRutasProvincias } from './routes/provincias.js';

// Crea y configura la app sin arrancarla (sin listen), para que los tests
// puedan importarla y lanzarle peticiones sin abrir un puerto.
// Recibe el pool por parámetro: el servidor le pasa el de desarrollo y los
// tests el de adopciones_test.
export function crearApp(pool: Pool): Express {
  const app = express();

  // Ruta técnica: se queda en inglés por convención (ver CLAUDE.md).
  app.get('/api/health', (_req, res) => {
    res.json({ estado: 'ok' });
  });

  app.use(crearRutasProvincias(pool));

  // Después de todas las rutas: cualquier /api/… que no haya atendido nadie → 404
  app.use('/api', rutaNoEncontrada);

  // Siempre el último: atiende los errores de todas las rutas anteriores
  app.use(manejarErrores);

  return app;
}
