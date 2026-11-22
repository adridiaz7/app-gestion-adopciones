# CLAUDE.md

Plataforma web de adopción de mascotas que maneja solicitudes, visitas y adopciones.

Estado actual: **andamiaje del backend listo**. Hay reglas de negocio, casos de uso, base de datos PostgreSQL, mockups y especificación técnica. El backend solo tiene `GET /api/health` y la carga de configuración (`src/server/app.ts`, `server.ts` y `config/`, con sus tests). Todavía no hay funcionalidades de negocio ni frontend.

## Comandos

Entorno: Windows, con PowerShell y Git Bash.

- Instalar: npm install
- Tests: npm test (todos) · npm run test:unit (solo unitarios) · npm run test:watch
- Comprobar tipos: npm run typecheck
- Lint: npm run lint
- Desarrollo: npm run dev (tsx watch; necesita un `.env`, copia de `.env.example`)
- Compilar / producción: npm run build · npm start

## Convenciones

- **TypeScript estricto: prohibido `any`** (ESLint lo trata como error).
- **Módulos ESM:** los imports relativos llevan la extensión `.js` (`import { crearApp } from './app.js'`).
- **Acceso a datos con `pg`:** SQL a mano y siempre parametrizado (`$1`, `$2`…). Nunca concatenar valores ni usar ORM.
- Tests con **Vitest**; las peticiones HTTP, con **supertest**.
- El tiempo se inyecta (interfaz Reloj). Nunca `new Date()` dentro del dominio.
- Errores de negocio con clases propias, no con strings.
- **Idioma del código: español** (lenguaje del dominio, DDD). En español: identificadores (variables, funciones, clases, tipos), comentarios, mensajes de error, nombres de los tests y propiedades del JSON.
  - Excepciones: tablas y columnas de la BD (inglés, fijado en `schema.sql`), APIs de librerías (`req`, `res`, `app.get`…) y nombres de carpetas y archivos técnicos (`models/`, `controllers/`, `app.ts`…).
  - El puente entre los nombres de la BD y los del código es el glosario de `database/README.md`.
  - URLs: las de negocio en español, sin tildes ni eñes (`/api/mascotas`, `/api/recuperar-contrasena`); las técnicas en inglés (`/api/health`). Criterio: si el concepto aparece en los casos de uso, va en español.
- **JSON de la API en `camelCase` y en español** (`{ "fechaNacimiento": … }`). El modelo traduce las filas desde los nombres de la BD; los tipos viven en `src/shared/`.
- **Citar las reglas en el código:** en SQL con `-- RN-08` y en TS con `// RN-08`; en los tests, el `describe` lleva el caso de uso y el `it` la regla (`describe('CU-23 · Solicitar una visita')`, `it('RN-xx: …')`).

## Forma de trabajar (acordada con el usuario)

- **Consultar antes de tomar cualquier decisión** (tecnología, diseño, nombres, alcance). Plantea las opciones con una recomendación argumentada y espera la respuesta.
- No cambies contraseñas ni la configuración de seguridad de PostgreSQL. Para probar el esquema, usa una base de datos o un clúster temporal.
- Haz TDD
- Planifica antes de editar.
- No digas que algo está hecho sin haber ejecutado `npm test`, `npm run typecheck` y `npm run lint`, y que los tres pasen.
- Después de implementar una funcionalidad, revísala con el agente `revisor`.
- Explica cada decisión que tomes de forma didáctica.

## Decisiones pendientes

No las resuelvas por tu cuenta: consulta antes. Cuando se decida una, pasa a `docs/TECH_SPEC.md` y se borra de aquí.

- **Autenticación.**
- **Envío de emails** (CU-03 verificar email, CU-05 recuperar contraseña).
- **Subida y almacenamiento de imágenes** (fotos de mascotas, logos, avatares, imagen del chat).
- **Tareas programadas** (CU-45…48).
- **Zona horaria de los turnos.**
- **Validación del formato de entrada** (manual o con librería): se decide al llegar al registro; la opción preferida es Zod.

## Documentación de referencia

- `docs/reglas-de-negocio.md`: reglas numeradas `RN-01…RN-174`. **Los identificadores están congelados**: una regla nueva recibe el siguiente número libre aunque se coloque en otra sección, y una regla eliminada no libera su número.
- `docs/casos-de-uso.md`: casos de uso `CU-01…CU-48`. Están completos y guían el desarrollo de cada funcionalidad.
- `docs/TECH_SPEC.md`: stack, herramientas, arquitectura, convenciones de la API y resumen del esquema.
- `database/README.md`: puesta en marcha, seeds, dump, usuarios de desarrollo y **glosario español ↔ inglés** de tablas, estados y enums.
- `docs/ux-ui/`: diseños de referencia en PNG (`acceso/`, `app-adoptante/`, `landing.png`) y `design-system.md`.
- `docs/mockups/prototipo-paleta-1.html`: prototipo navegable del adoptante. Es HTML autocontenido: los tokens de color están en `:root` y las pantallas se pintan con un `render()` de JS vanilla.

## Estructura de carpetas (acordada)

Se organiza **por capa**, sin agrupar por funcionalidad. Las carpetas se crean cuando hace falta el primer archivo de cada una.

```
├── database/              schema.sql, seeds y dump
├── docs/                  Reglas, casos de uso, spec y UX
├── src/
│   ├── server/            Backend (Express + pg)
│   │   ├── app.ts         Crea y configura Express, sin listen (los tests la importan)
│   │   ├── server.ts      Arranca el servidor (listen)
│   │   ├── config/        Único sitio que lee process.env; valida y tipa la configuración
│   │   ├── db/            Pool de pg y helper de transacción (hace SET LOCAL app.current_user_id)
│   │   ├── domain/        Reglas puras: errores propios e interfaz Reloj. Sin SQL ni Express
│   │   ├── models/        SQL por entidad (M)
│   │   ├── controllers/   Validan, llaman al modelo y responden JSON (C)
│   │   ├── routes/        URL + verbo HTTP → controlador
│   │   └── middlewares/   Errores de negocio → HTTP, validación y autenticación
│   ├── client/            TS del navegador (V)
│   │   ├── api/           Funciones con fetch hacia la API
│   │   └── pages/         Lógica de cada pantalla
│   └── shared/            Tipos de los JSON de la API, comunes a cliente y servidor
├── public/                HTML, CSS e imágenes, servidos con express.static
├── tests/
│   ├── unit/              Dominio, sin BD y con un Reloj falso
│   ├── integration/       API y SQL contra una BD temporal
│   └── helpers/           Reloj falso, BD temporal y datos de prueba
└── dist/                  Salida compilada (no se versiona)
```

- **Un solo `package.json`** en la raíz. Configuraciones de TypeScript:
  - `tsconfig.base.json`: opciones estrictas comunes.
  - `tsconfig.json`: servidor + `shared` + tests, sin generar archivos. Lo usan VS Code y `npm run typecheck`.
  - `tsconfig.server.json`: compila `src/server` y `src/shared` a `dist/` (`npm run build`).
  - `tsconfig.client.json` (**pendiente**: se crea con el primer archivo de `src/client`): incluye `src/client` y `src/shared`, con `lib: ["DOM"]`. Así el cliente no puede importar código del servidor.
- **Tests:** `unit/` es código puro, sin Express ni BD; `integration/` es todo lo que pasa por Express o PostgreSQL.
- **Variables de entorno:**
  - `.env` es la configuración de desarrollo y `.env.test` la de los tests, que apunta a la BD temporal. Ninguno de los dos se versiona.
  - `.env.example` es la plantilla versionada, con valores ficticios.
  - Se cargan con la opción nativa `node --env-file=...`, sin `dotenv`.

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
