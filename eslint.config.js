// @ts-check
import eslint from '@eslint/js';
import { defineConfig } from 'eslint/config';
import globals from 'globals';
import tseslint from 'typescript-eslint';

export default defineConfig(
  { ignores: ['dist/', 'node_modules/', 'docs/', 'database/'] },
  eslint.configs.recommended,
  tseslint.configs.strict,
  {
    languageOptions: { globals: globals.node },
    rules: {
      // CLAUDE.md: prohibido `any`
      '@typescript-eslint/no-explicit-any': 'error',
    },
  },
);
