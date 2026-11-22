---
name: autenticador
description: Implementa el registro, la verificación de email, el login, las sesiones y la gestión de contraseñas (CU-01…CU-05), siguiendo las reglas de auth y las convenciones de CLAUDE.md.
tools: Read, Edit, Write, Grep, Glob, Bash
---

Antes de empezar, lee CLAUDE.md: sus convenciones (idioma, pg sin ORM, Reloj,
errores propios, formato de los tests) se aplican también aquí.

## Autenticación y sesiones: reglas no negociables

Arquitectura
- Sesiones en servidor, guardadas en la tabla `session`. NO usar JWT.
- El token de sesión viaja solo en una cookie HttpOnly. NUNCA en localStorage,
  sessionStorage, cuerpos de respuesta ni URLs.
- Utilidades de auth en `src/server/auth/`: `contrasena.ts` (hash y verificación),
  `token.ts` (generar y calcular el SHA-256) y `cookie.ts`.
- El resto sigue las capas de CLAUDE.md: SQL en `models/`, lógica de la petición
  en `controllers/`, URL en `routes/` y la comprobación de la sesión en `middlewares/`.

Contraseñas
- Hash con Argon2id usando `@node-rs/argon2` y los parámetros de
  `src/server/auth/contrasena.ts`.
- Prohibido: guardar contraseñas en claro, cifrarlas, usar SHA/MD5 para ellas,
  escribirlas en logs o devolverlas en respuestas.

Tokens
- Generar con `crypto.randomBytes(32)`. Prohibido Math.random, Date.now o uuid como secreto.
- En la BD se guarda el SHA-256 del token, nunca el token.

Tiempo
- Las caducidades (sesión, enlaces, cookie) se calculan con el Reloj inyectado.
  Nunca `new Date()` en el dominio. Los tests usan un Reloj falso.

Cookie
- HttpOnly, SameSite=Lax, Path=/, Secure en producción. Usar `expires`, no `maxAge`.
- Toda la gestión de la cookie pasa por `src/server/auth/cookie.ts`.

Comportamiento
- Login: mismo mensaje y mismo tiempo si el email no existe o la contraseña falla.
- Login: crear SIEMPRE una sesión nueva e invalidar la anterior.
- Login: rechazar si el email no está verificado (RN-07) o la cuenta está
  suspendida (RN-10).
- Logout: borrar la sesión en la BD y después la cookie.
- Cambio o recuperación de contraseña: invalidar todas las sesiones del usuario.
- Respuestas con usuario: usar `usuarioPublico()`. Nunca devolver la fila completa.
- Emails: a través de la interfaz `EnviadorEmail`. Por ahora, la implementación
  escribe el enlace en consola (sin la palabra "token" en la línea del log), y
  en los tests se usa un doble que lo guarda.

Autorización
- Todo /api requiere sesión salvo lo listado en RUTAS_PUBLICAS
  (src/server/app.ts). Añadir una ruta pública exige pedírmelo antes.
- Las consultas a recursos de usuario filtran por propietario en la propia consulta.

Proceso
- NO modificar ni borrar nada en `tests/unit/auth/` ni en
  `tests/integration/auth/` sin permiso explícito.
- NO añadir dependencias sin permiso. Versiones fijadas en package.json.
- NO modificar `database/schema.sql` sin permiso. Si se cambia, actualizar el
  glosario de `database/README.md` y regenerar `dump.sql`.
- Si un test de auth falla, se arregla el código, no el test.
- Antes de dar una tarea por terminada: `npm run test:auth`, `npm test`,
  `npm run typecheck` y `npm run lint` en verde.

## Tests obligatorios
Ubicación: `tests/integration/auth/` (con HTTP o BD) y `tests/unit/auth/` (código puro).
Nombres según CLAUDE.md: `describe` con el caso de uso, `it` con la regla.

1. El hash guardado empieza por `$argon2id$` y no contiene la contraseña.
2. El login correcto devuelve una cookie con HttpOnly, SameSite=Lax, Path=/ y caducidad a 30 días.
3. El valor de la cookie no aparece en la tabla `session`; su SHA-256 sí.
4. Email inexistente y contraseña incorrecta dan el mismo estado y el mismo cuerpo.
5. Tras el logout, la cookie antigua recibe 401 en `GET /api/sesion`.
6. Una sesión con `expires_at` pasado recibe 401 y se borra.
7. Hacer login con una cookie previa genera un token distinto e invalida el anterior.
8. Todas las rutas no públicas responden 401 sin cookie.
9. (Aplazado hasta que exista un recurso con propietario) Ana no puede leer,
   editar ni borrar un recurso de Luis (404).
10. `GET /api/sesion` devuelve exactamente las claves de `usuarioPublico`.
11. El intento 11 de login en 15 minutos recibe 429.
12. Un enlace de restablecimiento funciona una vez; la segunda da error. Uno caducado da error.
13. Cambiar la contraseña invalida las demás sesiones del usuario.
14. Una petición POST con un Origin ajeno es rechazada.
15. No se puede iniciar sesión sin haber verificado el email (RN-07).
16. Un usuario suspendido no puede iniciar sesión (RN-10).

## Stack (cerrado)
- Node 24, TypeScript estricto, Express 5, Zod, Vitest + supertest
- BD: PostgreSQL con `pg`, SQL a mano y parametrizado. Sin ORM.
- Hash: @node-rs/argon2 (Argon2id, m=19456, t=2, p=1)
- Límite de intentos: express-rate-limit (en memoria)

## Endpoints
| Método | Ruta                          | CU    | Pública | Respuesta OK               |
|--------|-------------------------------|-------|---------|----------------------------|
| POST   | /api/registro/adoptante       | 01    | sí      | 201 { usuario }            |
| POST   | /api/registro/protectora      | 02    | sí      | 201 { usuario }            |
| POST   | /api/verificar-email          | 03    | sí      | 204                        |
| POST   | /api/sesion                   | 04    | sí      | 200 { usuario } + cookie   |
| GET    | /api/sesion                   | 04    | no      | 200 { usuario }            |
| DELETE | /api/sesion                   | 04    | no      | 204                        |
| DELETE | /api/sesiones                 | 04    | no      | 204                        |
| PUT    | /api/contrasena               | 06    | no      | 204                        |
| POST   | /api/recuperar-contrasena     | 05    | sí      | 202 (siempre)              |
| POST   | /api/restablecer-contrasena   | 05    | sí      | 204                        |

## Reglas de negocio (ver docs/reglas-de-negocio.md)
- RN-175: contraseña de 12 a 256 caracteres, sin reglas de composición.
- RN-176: sesión de 30 días deslizantes; se renueva si quedan menos de 15.
- RN-177: el enlace de verificación vale 24 h.
- RN-178: el enlace de restablecimiento vale 30 min y es de un solo uso.
- RN-179: máximo 10 intentos de login cada 15 min por IP.
- RN-07: sin email verificado, la cuenta no está activa (no puede iniciar sesión).
- RN-10: un usuario suspendido no puede iniciar sesión.
- Registro con un email existente: 409 "Ya existe una cuenta con ese email".
- El registro crea la cuenta (`app_user`) y el perfil (`adopter` o `shelter`) en
  UNA sola transacción (RN-171): nunca queda una cuenta sin perfil. Cada rol
  tiene su endpoint porque recibe datos distintos (CU-01, CU-02).

## Orden de trabajo (una /nueva-funcionalidad por parte)
1. CU-01 · Registro de adoptante (incluye todo lo común: Argon2id, Zod,
   enlace de verificación, EnviadorEmail).
2. CU-02 · Registro de protectora (CIF único, pendiente de validación).
3. CU-03 · Verificar el email.
4. CU-04 · Login, sesión, logout, límite de intentos y Origin. Incluye rehacer
   con Argon2id los hashes bcrypt (`$2a$10$`) de `seed.sql` y `seed_demo.sql`,
   con la MISMA contraseña de desarrollo, y regenerar `dump.sql`. Si no, los
   usuarios de demo no pueden iniciar sesión.
5. CU-05 y cambio de contraseña.

## Errores
Formato: `{ error: { codigo, mensaje } }`, lanzados con clases de error propias.
| Estado | codigo                   | mensaje                                  |
|--------|--------------------------|------------------------------------------|
| 400    | DATOS_NO_VALIDOS         | Datos no válidos                         |
| 401    | CREDENCIALES_INCORRECTAS | Email o contraseña incorrectos           |
| 401    | NO_AUTENTICADO           | No autenticado                           |
| 403    | SIN_PERMISO              | Sin permiso                              |
| 403    | EMAIL_NO_VERIFICADO      | Debes verificar tu email antes de entrar |
| 403    | CUENTA_SUSPENDIDA        | Tu cuenta está suspendida                |
| 409    | EMAIL_YA_REGISTRADO      | Ya existe una cuenta con ese email       |
| 429    | DEMASIADOS_INTENTOS      | Demasiados intentos. Prueba más tarde.   |

## Forma de usuarioPublico
{ id, email, rol, emailVerificado: boolean }

## Fuera de alcance
- OAuth, MFA, passkeys
- Envío real de emails (decisión pendiente)
