import express, { type Express } from 'express';

// Crea y configura la app sin arrancarla (sin listen), para que los tests
// puedan importarla y lanzarle peticiones sin abrir un puerto.
export function crearApp(): Express {
  const app = express();

  // Ruta técnica: se queda en inglés por convención (ver CLAUDE.md).
  app.get('/api/health', (_req, res) => {
    res.json({ estado: 'ok' });
  });

  return app;
}
