import { fileURLToPath } from 'node:url';
import express, { type Express } from 'express';
import type { Pool } from 'pg';
import { enviadorEmailDeConsola, type EnviadorEmail } from './auth/enviador-email.js';
import type { Reloj } from './domain/reloj.js';
import { manejarErrores, rutaNoEncontrada } from './middlewares/errores.js';
import { crearRutasProvincias } from './routes/provincias.js';
import { crearRutasRegistro } from './routes/registro.js';

// Lo que la app necesita del exterior, además del pool. Todo es opcional:
// el servidor usa los valores reales y cada test sustituye solo lo que le
// interesa (un Reloj falso, un EnviadorEmail que guarda lo enviado…).
export interface DependenciasApp {
  reloj?: Reloj;
  enviadorEmail?: EnviadorEmail;
  urlPublica?: string;
}

// El reloj de verdad. Es el único sitio donde se lee la hora del sistema:
// el dominio la recibe siempre a través de la interfaz Reloj.
const relojDelSistema: Reloj = { ahora: () => new Date() };

// Carpeta public/ calculada desde este archivo, no desde el directorio en el
// que se lanza node: funciona igual desde src/server/ (tsx) y desde
// dist/server/ (compilado), porque ambos están dos niveles por debajo.
const CARPETA_PUBLIC = fileURLToPath(new URL('../../public', import.meta.url));

// Crea y configura la app sin arrancarla (sin listen), para que los tests
// puedan importarla y lanzarle peticiones sin abrir un puerto.
// Recibe el pool por parámetro: el servidor le pasa el de desarrollo y los
// tests el de adopciones_test.
export function crearApp(pool: Pool, dependencias: DependenciasApp = {}): Express {
  const reloj = dependencias.reloj ?? relojDelSistema;
  const enviadorEmail = dependencias.enviadorEmail ?? enviadorEmailDeConsola;
  const urlPublica = dependencias.urlPublica ?? 'http://localhost:3000';

  const app = express();

  // Interpreta los cuerpos JSON (req.body). Si el JSON está mal formado,
  // lanza un error que el middleware de errores convierte en 400.
  app.use(express.json());

  // HTML, CSS y el JavaScript compilado del cliente (public/js/).
  // Página y API comparten origen: la cookie de sesión funcionará sin CORS.
  app.use(express.static(CARPETA_PUBLIC));

  // Ruta técnica: se queda en inglés por convención (ver CLAUDE.md).
  app.get('/api/health', (_req, res) => {
    res.json({ estado: 'ok' });
  });

  app.use(crearRutasProvincias(pool));
  app.use(crearRutasRegistro(pool, reloj, enviadorEmail, urlPublica));

  // Después de todas las rutas: cualquier /api/… que no haya atendido nadie → 404
  app.use('/api', rutaNoEncontrada);

  // Siempre el último: atiende los errores de todas las rutas anteriores
  app.use(manejarErrores);

  return app;
}
