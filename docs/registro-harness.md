# Registro del harness

Fallos del agente (o de sus herramientas) que **se pueden repetir**, y el cambio en el harness que los evita: una regla en `CLAUDE.md`, un hook, un script o una instrucción a un agente.

- **Entra:** un error que podría volver a pasar en otra funcionalidad.
- **No entra:** un fallo puntual (basta con el test que lo reproduce) ni una decisión sin tomar (va a "Decisiones pendientes" de `CLAUDE.md`).
- **"Cambio en el harness"** dice dónde está el cambio, para poder encontrarlo y quitarlo si un día sobra. Si aún no hay cambio: **Pendiente**.

| Fecha | Fallo del agente / error | Cambio en el harness |
|---|---|---|
| 22/11/2026 | El hook `check-auth.sh`, copiado de los apuntes, bloqueaba cada respuesta en bucle: no había tests de auth y Vitest no busca en `tests/auth/` | `scripts/check-auth.sh`: termina sin error si no hay tests; usa `tests/unit/auth` y `tests/integration/auth` |
| 22/11/2026 | El guardián buscaba `password`, pero el código está en español: un `console.log(contrasena)` se le escapaba | `scripts/check-auth.sh`: patrones `contrasena` y `contraseña` |
| 22/11/2026 | El agente `autenticador` podía terminar con los tests de auth en rojo: el hook `Stop` no se ejecuta al terminar un subagente | `.claude/settings.json`: hook `SubagentStop` con `check-auth.sh` |
| 23/11/2026 | Dos ejecuciones de Vitest a la vez (los dos comandos del hook `Stop` en paralelo, otra sesión de Claude en el mismo proyecto…) se borraban `adopciones_test` la una a la otra: fallos intermitentes de "no existe la base de datos" | `tests/helpers/globalSetup.ts`: advisory lock de PostgreSQL durante toda la ejecución (la segunda espera). Además, `.claude/settings.json`: `npm test` y `check-auth.sh` en un solo comando, en orden |
| 23/11/2026 | Fechas comparadas como texto: con el año 9999, `"10017-…"` quedaba antes que `"2026-…"` y se saltaba RN-25 | `CLAUDE.md` › Convenciones: las fechas se comparan como números |
| 23/11/2026 | Un id de entrada mayor que su columna (`smallint`) llegaba a PostgreSQL y daba 500 | `CLAUDE.md` › Convenciones: todo id de entrada lleva un `max` según el tipo de su columna |
| 23/11/2026 | Si el envío del email falla después del COMMIT, la respuesta es 500 pero la cuenta ya existe: reintentar da 409 y el usuario queda bloqueado | Pendiente (depende de la decisión sobre los efectos externos, en `CLAUDE.md` › Decisiones pendientes) |
