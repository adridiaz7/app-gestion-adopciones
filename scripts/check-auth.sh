#!/usr/bin/env bash
# scripts/check-auth.sh
# Guardián de las reglas de auth (.claude/agents/autenticador.md).
# Se ejecuta en los hooks Stop y SubagentStop: exit 2 impide terminar el turno.
set -uo pipefail

# Los tests de auth siguen nuestra separación: unitarios (sin BD) y de integración
DIRS_AUTH="tests/unit/auth tests/integration/auth"
# "contrasena|contraseña" porque el código del proyecto está en español
FORBIDDEN="localStorage|sessionStorage|Math\.random|jsonwebtoken|['\"]jose['\"]|console\.(log|info|debug)\(.*(password|contrasena|contraseña|token)"

# Mientras no exista ningún test de auth, no hay nada que comprobar
if ! ls tests/unit/auth/*.test.ts tests/integration/auth/*.test.ts >/dev/null 2>&1; then
  exit 0
fi

if grep -rnE "$FORBIDDEN" src/ ; then
  echo "Patrón prohibido en src/. Revisa las reglas de .claude/agents/autenticador.md." >&2
  exit 2
fi

# shellcheck disable=SC2086 # DIRS_AUTH se separa en dos rutas a propósito
if ! git diff --quiet HEAD -- $DIRS_AUTH ; then
  echo "Se han modificado tests de auth. No está permitido sin permiso." >&2
  exit 2
fi

# shellcheck disable=SC2086
if ! npx vitest run $DIRS_AUTH --reporter=dot ; then
  echo "Los tests de auth fallan. Arregla el código, no los tests." >&2
  exit 2
fi
