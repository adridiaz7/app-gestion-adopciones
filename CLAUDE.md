# CLAUDE.md

Plataforma web de adopción de mascotas que maneja solicitudes, visitas y adopciones.

Estado actual: **registro de adoptante (CU-01) listo, con sus pantallas**. Hay reglas de negocio, casos de uso, base de datos PostgreSQL, mockups y especificación técnica. El backend tiene `GET /api/health`, el catálogo `GET /api/provincias`, `POST /api/registro/adoptante`, el middleware de errores por categorías y la BD de tests (`adopciones_test`, recreada en cada `npm test`). El frontend tiene las pantallas de tipo de cuenta y registro de adoptante. Todavía no hay login ni sesiones.

## Comandos

Entorno: Windows, con PowerShell y Git Bash.

- Instalar: npm install
- Tests: npm test (todos) · npm run test:unit (solo unitarios) · npm run test:auth (solo auth) · npm run test:watch
- Comprobar tipos: npm run typecheck
- Lint: npm run lint
- Desarrollo: npm run dev (compila el cliente una vez y arranca el servidor con tsx watch; necesita un `.env`, copia de `.env.example`) · npm run dev:client (recompila el cliente al guardar; en otra terminal)
- Compilar / producción: npm run build (servidor y cliente) · npm run build:client (solo cliente) · npm start

## Convenciones

- **TypeScript estricto: prohibido `any`** (ESLint lo trata como error).
- **Módulos ESM:** los imports relativos llevan la extensión `.js` (`import { crearApp } from './app.js'`).
- **Acceso a datos con `pg`:** SQL a mano y siempre parametrizado (`$1`, `$2`…). Nunca concatenar valores ni usar ORM.
- El tiempo se inyecta (interfaz Reloj). Nunca `new Date()` dentro del dominio.
- Errores de negocio con clases propias, no con strings.
- **Idioma del código: español** (lenguaje del dominio, DDD). En español: identificadores (variables, funciones, clases, tipos), comentarios, mensajes de error, nombres de los tests y propiedades del JSON.
  - Excepciones: tablas y columnas de la BD (inglés, fijado en `schema.sql`), APIs de librerías (`req`, `res`, `app.get`…) y nombres de carpetas y archivos técnicos (`models/`, `controllers/`, `app.ts`…).
  - El puente entre los nombres de la BD y los del código es el glosario de `database/README.md`.
  - URLs: las de negocio en español, sin tildes ni eñes (`/api/mascotas`, `/api/recuperar-contrasena`); las técnicas en inglés (`/api/health`). Criterio: si el concepto aparece en los casos de uso, va en español.
- **JSON de la API en `camelCase` y en español** (`{ "fechaNacimiento": … }`). El modelo traduce las filas desde los nombres de la BD; los tipos viven en `src/shared/`.
- **Citar las reglas en el código:** en SQL con `-- RN-08` y en TS con `// RN-08` (en los tests, ver la sección Tests).
- **Fechas:** se comparan como números (año, mes, día), no como texto. Como texto solo si el formato está garantizado (por ejemplo, tras `z.iso.date()`).
- **Ids de entrada:** llevan un `max` según el tipo de su columna (`smallint` 32767, `integer` 2147483647). Si no, un número grande llega a PostgreSQL y da 500.

## Tests

Las decisiones de fondo (BD de los tests, por qué no se usa ROLLBACK…) están en `docs/TECH_SPEC.md`, sección Tests. Aquí solo van reglas que se pueden comprobar al leer un test.

- **Herramientas:** Vitest; las peticiones HTTP, con supertest.
- **Dónde va cada test:** `unit/` es código puro, sin Express ni conexión a la BD; `integration/` es todo lo que pasa por Express o PostgreSQL.
- **Nombres:** el `describe` lleva el caso de uso y el `it` la regla (`describe('CU-23 · Solicitar una visita')`, `it('RN-xx: …')`).
  - Si un endpoint sirve a varios casos de uso: `describe('Nombre · VERBO /ruta (CU-xx, CU-yy)')`.
  - Los tests de contrato (forma del JSON, orden) no prueban ninguna regla: su `it` va sin cita.
- **Errores:** todo error de la API sale como `{ error: { codigo, mensaje } }`, también los 404 de ruta y los 400 de un body mal formado. El formato del 500 se prueba una vez, en `errores.test.ts` (el middleware es común a todas las rutas).
- **Dobles de prueba:** imitan solo lo que usa el código y lo dicen en un comentario (por ejemplo, un `Pool` falso que solo tiene `query`).
- **`console.error`:** en los tests que provocan errores, se espía y se silencia con `vi.spyOn(console, 'error').mockImplementation(() => undefined)`, y se restaura con `vi.restoreAllMocks()` en `afterEach`.
- **Listas:** comprueba que el elemento existe antes de usar su posición (`indexOf` devuelve -1 si no está), y verifica el orden sobre la lista entera, no solo sobre un par de vecinos.

## Forma de trabajar

- **Consultar antes de tomar cualquier decisión** (tecnología, diseño, nombres, alcance). Plantea las opciones con una recomendación argumentada y espera la respuesta.
- No cambies contraseñas ni la configuración de seguridad de PostgreSQL. Para probar el esquema, usa una base de datos o un clúster temporal.
- Haz TDD
- Planifica antes de editar.
- No digas que algo está hecho sin haber ejecutado `npm test`, `npm run typecheck` y `npm run lint`, y que los tres pasen.
- Después de implementar una funcionalidad, revísala con el agente `revisor`.
- Explica cada decisión que tomes de forma didáctica.

## Decisiones pendientes

No las resuelvas por tu cuenta: consulta antes. Cuando se decida una, pasa a `docs/TECH_SPEC.md` y se borra de aquí.

- **Envío de emails** (CU-03 verificar email, CU-05 recuperar contraseña). Mientras tanto, la interfaz `EnviadorEmail` escribe el enlace en la consola.
- **Subida y almacenamiento de imágenes** (fotos de mascotas, logos, avatares, imagen del chat).
- **Tareas programadas** (CU-45…48).
- **Zona horaria de los turnos.** CU-01 ya calcula "hoy" en `Europe/Madrid` para la mayoría de edad.

Surgidas en la revisión de CU-01:

- **Fallo de un efecto externo tras el COMMIT** (el email del registro): ¿se responde 201 y se registra el fallo, en vez de 500?
- **Normalizar la contraseña (NFC) antes del hash**, para que una "ñ" escrita en otro sistema operativo dé el mismo hash. Decidir antes de CU-04.
- **Limpieza de la BD en los tests:** hoy es DELETE de todo menos el ADMIN, y fallará en CU-04 por la FK de `audit_log`. ¿Pasar a `TRUNCATE … CASCADE` y volver a cargar el admin?
- **`PUBLIC_URL`:** ¿validarla con `new URL()` y dejar el valor por defecto en un solo sitio (hoy está también en `app.ts`)?
- **Documentación de CU-01:** llevar a `TECH_SPEC.md` el token en el fragmento (`#token=`) y `z.strictObject`.

## Documentación de referencia

- `docs/reglas-de-negocio.md`: reglas numeradas `RN-01…RN-179`. **Los identificadores están congelados**: una regla nueva recibe el siguiente número libre aunque se coloque en otra sección, y una regla eliminada no libera su número.
- `docs/casos-de-uso.md`: casos de uso `CU-01…CU-48`. Están completos y guían el desarrollo de cada funcionalidad.
- `docs/TECH_SPEC.md`: stack, herramientas, arquitectura, convenciones de la API, autenticación y resumen del esquema.
- `docs/registro-harness.md`: fallos del agente que se pueden repetir y el cambio del harness que los evita. Cuando un fallo así aparezca, se añade una fila.
- `.claude/agents/autenticador.md`: reglas no negociables de auth, endpoints y tests obligatorios. Lo vigila `scripts/check-auth.sh` (hooks `Stop` y `SubagentStop`).
- `database/README.md`: puesta en marcha, seeds, dump, usuarios de desarrollo y **glosario español ↔ inglés** de tablas, estados y enums.
- `docs/ux-ui/`: diseños de referencia en PNG (`acceso/`, `app-adoptante/`, `landing.png`) y `design-system.md`.
- `docs/mockups/prototipo-paleta-1.html`: prototipo navegable del adoptante. Es HTML autocontenido: los tokens de color están en `:root` y las pantallas se pintan con un `render()` de JS vanilla.

## Dónde va cada cosa

El árbol completo de carpetas y los `tsconfig` están en `docs/TECH_SPEC.md` (Arquitectura). Aquí van las reglas que no se ven en los archivos:

- Se organiza **por capa** (`models/`, `controllers/`, `routes/`…), nunca por funcionalidad. Una carpeta se crea cuando hace falta su primer archivo.
- `src/server/domain/`: reglas puras. Sin SQL, sin Express y sin leer la hora (la da el Reloj).
- `src/server/models/`: todo el SQL, y la traducción entre los nombres de la BD y los del código.
- `src/server/controllers/`: validan la entrada (Zod), llaman al dominio y al modelo, y responden. Sin SQL.
- `src/server/config/`: el **único** sitio que lee `process.env`. Las variables se cargan con `node --env-file`, sin `dotenv`; `.env` y `.env.test` no se versionan (la plantilla es `.env.example`).
- `src/client/` (navegador) tiene su propio `tsconfig.client.json`: **no puede importar** nada de `src/server/`. Lo que comparten cliente y servidor (tipos del JSON) va en `src/shared/`.
- `public/js/` lo genera `tsc` desde `src/client/`: no se edita a mano ni se versiona.
- Tests: `tests/unit/` sin BD ni Express; `tests/integration/` con supertest y `adopciones_test`; dobles y helpers en `tests/helpers/`.

## Base de datos

- No repitas en el chat las contraseñas de desarrollo (están en `database/README.md`).
- `dump.sql` se genera con `pg_dump` (PostgreSQL 18). Si cambian `schema.sql` o los seeds, hay que regenerarlo.

### Claves del esquema (`database/schema.sql`)

Está organizado en secciones numeradas:

| Sección | Contenido |
|---|---|
| 1 | ENUM |
| 2–9 | Tablas |
| 10 | Índices únicos que imponen reglas de negocio |
| 11 | Índices de FK y de búsqueda |
| 12 | `updated_at` automático |
| 13 | Auditoría |

**Nunca se borran registros con historial.** Por defecto se usa `ON DELETE RESTRICT`, y `CASCADE` solo en entidades débiles. Las cuentas se anonimizan con `deleted_at`.

**Muchas reglas de negocio se imponen en la propia BD** con `CHECK`, índices únicos parciales y claves compuestas. Antes de reimplementar una regla en el backend, comprueba si el esquema ya la garantiza. Ejemplo: una `adoption` procede siempre de una `visit` del mismo adoptante y la misma mascota, mediante una FK compuesta.

**Auditoría:** el trigger `fn_audit` escribe en `audit_log`. Solo audita las tablas de decisiones: `app_user`, `adopter`, `shelter`, `suspension`, `pet`, `visit_slot`, `visit`, `adoption`, `adopter_block` e `incident`.
- El backend debe ejecutar `SET LOCAL app.current_user_id = '<id>'` dentro de cada transacción que modifique datos. Si no lo hace, `id_user` queda a `NULL`, que significa "lo hizo el sistema".
- `SET LOCAL app.skip_audit = 'on'` desactiva la auditoría, y solo se usa en cargas masivas.
- La columna `password` nunca se copia al log.

**Especie:** se obtiene a través de la raza (`pet.id_breed → breed.id_species`). No hay `id_species` en `pet`.
