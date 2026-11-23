// @ts-check
import eslint from '@eslint/js';
import { defineConfig } from 'eslint/config';
import globals from 'globals';
import tseslint from 'typescript-eslint';

export default defineConfig(
  // public/js/ es JavaScript generado por tsc a partir de src/client: se revisa el original
  { ignores: ['dist/', 'node_modules/', 'docs/', 'database/', 'public/js/'] },
  eslint.configs.recommended,
  tseslint.configs.strict,
  {
    languageOptions: { globals: globals.node },
    rules: {
      // CLAUDE.md: prohibido `any`
      '@typescript-eslint/no-explicit-any': 'error',
    },
  },
  {
    // El cliente se ejecuta en el navegador: document, window, fetch…
    files: ['src/client/**/*.ts'],
    languageOptions: { globals: globals.browser },
  },
);
