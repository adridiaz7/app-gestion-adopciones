import { existsSync, readFileSync } from 'node:fs';
import { parseEnv } from 'node:util';
import { defineConfig } from 'vitest/config';

// Variables de .env.test (la BD de los tests). Solo las usa el proyecto
// "integration". Si el archivo no existe, no se falla aquí, para que
// `npm run test:unit` funcione sin él; globalSetup avisará con un mensaje claro.
const entornoDeTest = existsSync('.env.test') ? parseEnv(readFileSync('.env.test', 'utf8')) : {};

export default defineConfig({
  test: {
    environment: 'node',
    projects: [
      {
        test: {
          name: 'unit',
          include: ['tests/unit/**/*.test.ts'],
        },
      },
      {
        test: {
          name: 'integration',
          include: ['tests/integration/**/*.test.ts'],
          env: entornoDeTest,
          // Recrea adopciones_test una vez, antes de todos los tests
          globalSetup: ['tests/helpers/globalSetup.ts'],
          // Todos los archivos comparten la misma BD: se ejecutan de uno en uno
          fileParallelism: false,
        },
      },
    ],
  },
});
