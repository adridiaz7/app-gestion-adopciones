# Especificación Técnica - Plataforma de Adopción de Mascotas

## Descripción General

La Plataforma de Adopción de Mascotas es un sistema que conecta **protectoras** y **adoptantes** para digitalizar el proceso de adopción de principio a fin y reducir su tiempo de gestión. Permite:

- Registrar adoptantes y protectoras, con verificación de email y validación de protectoras por el administrador
- Gestionar el catálogo de mascotas de cada protectora, con fotos, estado y baja
- Buscar mascotas en galería o en el modo descubrir (favorito / descartar), según las preferencias del adoptante
- Buscar protectoras y consultar su perfil
- Publicar turnos de visita y gestionar las solicitudes de visita y su asistencia
- Gestionar las solicitudes de adopción, comparar candidatos, registrar la entrega y las devoluciones
- Comunicarse por chat entre adoptante y protectora
- Enviar notificaciones de cada paso del proceso
- Bloquear adoptantes, suspender cuentas y resolver incidencias
- Mantener auditoría de cambios

---

## Tecnologías

### Frontend
- **HTML5**: Estructura y marcado semántico
- **CSS3**: Estilos y diseño responsivo, con los tokens del [sistema de diseño](ux-ui/design-system.md) como variables CSS
- **TypeScript**: Lógica de cliente con tipado estático; consume la API REST del backend con `fetch`
- **Sin framework de interfaz**: el DOM se manipula directamente con TypeScript
- **Compilación con `tsc`**: el compilador oficial de TypeScript genera el JavaScript que carga el navegador, sin empaquetador (bundler)

### Backend
- **Node.js + Express 5**: Servidor HTTP y API REST
- **TypeScript**: Implementación del servidor y lógica de negocio
- **pg (node-postgres)**: Acceso a la base de datos con SQL escrito a mano y consultas parametrizadas (sin ORM)
- **Zod**: validación del formato de los datos de entrada
- **@node-rs/argon2**: hash de contraseñas con Argon2id
- **express-rate-limit**: límite de intentos de inicio de sesión

### Base de Datos
- **PostgreSQL** (versión 11 o superior; desarrollado y probado en la 18): Sistema de gestión de datos relacional

### Herramientas
- **Node.js 24** con módulos **ESM** (`"type": "module"` y `module: NodeNext`): los imports relativos llevan la extensión `.js`
- **TypeScript** en modo estricto, con un `tsconfig` por destino (base común, servidor y, más adelante, cliente)
- **tsx**: ejecuta el TypeScript directamente durante el desarrollo (`npm run dev`)
- **Vitest** y **supertest**: tests unitarios y de integración de la API
- **ESLint** con `typescript-eslint` en modo `strict` (`no-explicit-any` da error)
- Variables de entorno con la opción nativa `node --env-file`, sin `dotenv`

---

## Arquitectura

Se sigue el patrón **MVC (Model-View-Controller)** sobre una **API REST**:

- **Model**: Capas de acceso a datos y lógica de negocio (TypeScript + PostgreSQL). Contiene las consultas SQL y aplica las reglas de negocio ([RN](reglas-de-negocio.md)) que no garantiza la propia base de datos.
- **View**: Interfaz de usuario (HTML + CSS), con TypeScript en el cliente para pedir los datos a la API y pintar las pantallas. Los diseños de referencia están en [`docs/ux-ui`](ux-ui).
- **Controller**: Lógica de coordinación entre vistas y modelos (TypeScript + Express). Recibe cada petición HTTP, valida los datos, llama al modelo y responde con JSON.

Flujo de una petición:

```
Vista (navegador) ──fetch──▶ Ruta Express ──▶ Controlador ──▶ Modelo ──SQL──▶ PostgreSQL
        ▲                                          │
        └──────────────── JSON ◀───────────────────┘
```

Esta arquitectura separa responsabilidades y facilita el mantenimiento y la escalabilidad de la aplicación. Además, frontend y backend pueden desarrollarse y probarse por separado.

---

## API REST

### Idioma: el lenguaje del dominio

El código, el JSON y las URLs de negocio están en **español**, siguiendo el principio de *lenguaje ubicuo* de DDD: los mismos términos en los casos de uso, en el código y en la API. El proyecto no tiene destinatarios internacionales, así que el inglés no aporta nada aquí. La base de datos es la excepción: su esquema ya está en inglés, y el [glosario de `database/README.md`](../database/README.md) hace de diccionario entre ambos.

### URLs

- Todas cuelgan de `/api`.
- **Rutas de negocio en español**, sin tildes ni eñes, porque las URLs solo admiten ASCII sin codificar (`/api/mascotas`, `/api/protectoras`, `/api/recuperar-contrasena`).
- **Rutas técnicas en inglés** (`/api/health`): son infraestructura, no dominio, y las herramientas de monitorización esperan esos nombres.
- Criterio: si el concepto aparece en los casos de uso, va en español.

### Formato del JSON

- Propiedades en **`camelCase` y en español** (`{ "fechaNacimiento": "…", "idProtectora": 3 }`).
- La conversión desde los nombres de la BD (`birth_date`, `id_shelter`) se hace en el **modelo**. Así la API no depende del esquema: renombrar una columna no rompe el frontend.
- Los tipos de cada respuesta se definen en `src/shared/`, de modo que cliente y servidor comparten el mismo contrato.

### Errores

Todas las respuestas de error tienen la misma forma:

```json
{
  "error": {
    "codigo": "MASCOTA_NO_DISPONIBLE",
    "mensaje": "La mascota no está disponible para visitas"
  }
}
```

- `codigo`: constante en `MAYUSCULAS_CON_GUIONES`, pensada para el programa. El frontend decide qué hacer según el código, no según el texto.
- `mensaje`: texto en español, pensado para la persona; se puede mostrar en pantalla.

**El dominio no conoce HTTP.** Una misma regla se usa desde una petición web, desde un test unitario o desde una tarea programada, donde no hay HTTP. Por eso los errores de negocio se clasifican por **categoría** y un único middleware traduce la categoría a un código HTTP:

| Categoría (clase base del dominio) | HTTP | Cuándo |
|---|---|---|
| `ErrorDeValidacion` | 400 | Los datos no tienen el formato correcto |
| `NoAutenticado` | 401 | Hace falta iniciar sesión |
| `Prohibido` | 403 | Hay sesión, pero no hay permiso |
| `NoEncontrado` | 404 | El recurso no existe |
| `Conflicto` | 409 | Choca con el estado actual (mascota reservada, email repetido…) |

- Cada error concreto hereda de una categoría y define su `codigo` (`class MascotaNoDisponible extends Conflicto`). Al crear un error nuevo no hay que tocar el middleware.
- Cualquier otro error (un fallo de SQL, un error de programación) se responde con **500**, código `ERROR_INTERNO` y un mensaje genérico. El detalle interno nunca se envía al cliente: se registra en la consola del servidor.
- Una ruta de `/api` que no existe responde **404** con código `RUTA_NO_ENCONTRADA` (no es el `NoEncontrado` de negocio: aquí no existe la URL, allí no existe el recurso).

### Validación de la entrada

- El **formato** de los datos de entrada (tipos, campos obligatorios, longitudes) se valida con **Zod** en el controlador. Un fallo responde 400 con código `DATOS_NO_VALIDOS`.
- Las **reglas de negocio** (mayoría de edad, email repetido…) no son formato: siempre se comprueban en el dominio o en el modelo.

---

## Autenticación

Las reglas detalladas y los tests obligatorios están en el agente [`.claude/agents/autenticador.md`](../.claude/agents/autenticador.md); aquí va el resumen de las decisiones.

### Sesiones en servidor, no JWT

- Al iniciar sesión se crea una fila en `session` y el navegador recibe un **token aleatorio** (`crypto.randomBytes(32)`) en una cookie.
- En la BD se guarda el **SHA-256 del token**, nunca el token: quien lea la tabla no puede suplantar a nadie.
- Se descartó JWT porque un JWT no se puede revocar antes de que caduque. Con sesiones en servidor, cerrar sesión o cambiar la contraseña invalida el acceso al momento: basta con borrar la fila.
- La sesión dura 30 días deslizantes ([RN-176](reglas-de-negocio.md)). Cada inicio de sesión crea una sesión nueva e invalida la anterior.
- Las caducidades se calculan con el Reloj inyectado.

### Cookie

- `HttpOnly` (el JavaScript de la página no puede leerla, así que un XSS no la roba), `SameSite=Lax`, `Path=/` y `Secure` en producción. Caducidad con `expires`.
- El token nunca viaja en el cuerpo de una respuesta, en la URL ni en `localStorage`.

### Contraseñas

- Hash con **Argon2id** (`@node-rs/argon2`, m=19456, t=2, p=1, los parámetros que recomienda OWASP) ([RN-08](reglas-de-negocio.md)).
- Longitud de 12 a 256 caracteres, sin reglas de composición ([RN-175](reglas-de-negocio.md)).

### Enlaces por email

- Los enlaces de verificación de email (24 h, [RN-177](reglas-de-negocio.md)) y de restablecimiento de contraseña (30 min y un solo uso, [RN-178](reglas-de-negocio.md)) se guardan en `auth_token`, también como SHA-256.
- El envío pasa por la interfaz `EnviadorEmail`. Mientras no se decida el envío real, la implementación escribe el enlace en la consola.

### Protecciones

- **Límite de intentos:** 10 inicios de sesión cada 15 minutos por IP ([RN-179](reglas-de-negocio.md)), con `express-rate-limit` en memoria. Responde 429 con código `DEMASIADOS_INTENTOS`.
- **Mismo mensaje** si el email no existe o la contraseña falla, para no revelar qué emails están registrados.
- **Origin:** las peticiones que modifican datos con un `Origin` ajeno se rechazan (defensa contra CSRF, junto con `SameSite`).
- **Rutas públicas:** todo `/api` exige sesión salvo las listadas en `RUTAS_PUBLICAS`.

### Endpoints

| Método | Ruta | Uso |
|---|---|---|
| POST | `/api/registro/adoptante` | Crear cuenta y perfil de adoptante (CU-01) |
| POST | `/api/registro/protectora` | Crear cuenta y perfil de protectora (CU-02) |
| POST | `/api/verificar-email` | Verificar el email |
| POST · GET · DELETE | `/api/sesion` | Iniciar sesión · usuario actual · cerrar sesión |
| DELETE | `/api/sesiones` | Cerrar todas las sesiones |
| PUT | `/api/contrasena` | Cambiar la contraseña |
| POST | `/api/recuperar-contrasena` | Pedir el enlace de restablecimiento |
| POST | `/api/restablecer-contrasena` | Fijar la contraseña nueva con el enlace |

La sesión se trata como un recurso REST: se crea al entrar, se consulta para saber quién eres y se borra al salir.

El registro crea la cuenta y el perfil en **una sola transacción** ([RN-171](reglas-de-negocio.md)), para que nunca quede una cuenta sin perfil. Por eso hay un endpoint por rol: cada uno recibe datos distintos.

---

## Tests

- **Unitarios** (`tests/unit/`): dominio puro, sin Express ni base de datos, con un Reloj falso.
- **Integración** (`tests/integration/`): todo lo que pasa por Express o PostgreSQL, contra una base de datos propia de los tests.

### Base de datos de los tests

Los tests nunca usan la base de datos de desarrollo: usan `adopciones_test`, configurada en `.env.test`.

1. **Al empezar `npm test`**, una sola vez (`globalSetup` de Vitest): se borra y se vuelve a crear `adopciones_test`, y se cargan `schema.sql` y `seed.sql` (los catálogos).
2. **Antes de cada test**: `TRUNCATE` de las tablas que rellenan los tests. Los catálogos se conservan.
3. Los tests de integración se ejecutan **en serie**, porque comparten la misma base de datos.
4. **Dos `npm test` a la vez** (un hook, otra sesión, una terminal) también se pisarían: el `globalSetup` coge un *advisory lock* de PostgreSQL y lo mantiene hasta el final, así que la segunda ejecución espera a que termine la primera.

Así cada test empieza con la base de datos en un estado conocido y no depende del orden ni de lo que dejaron los demás. Se descartó envolver cada test en una transacción con `ROLLBACK`: es más rápido, pero obliga a pasar la misma conexión a todo el código y a usar `SAVEPOINT` cuando el código abre su propia transacción. Con el tamaño de este proyecto, la diferencia de velocidad no compensa esa complejidad.

---

## Base de Datos

### Esquema Relacional

Convenciones: nombres en inglés, claves foráneas con el prefijo `id_`, tablas N:M con el sufijo `_rel`, fechas en `timestamptz` y columnas de auditoría (`created_at`, `updated_at` y, en las tablas de negocio, `created_by` y `updated_by`). El esquema completo está en [`database/schema.sql`](../database/schema.sql) (30 tablas y 24 tipos ENUM).

#### Tablas Principales

**`app_user`**
- Cuenta de acceso común a los tres roles (adoptante, protectora y administrador)
- Campos: id, email, contraseña (hash), rol, email verificado, fecha de eliminación (cuenta anonimizada)

**`session`**
- Sesiones iniciadas de cada usuario (entidad débil de `app_user`)
- Campos: id, id_user, hash del token, caducidad

**`auth_token`**
- Enlaces de un solo uso enviados por email: verificar el email y restablecer la contraseña
- Campos: id, id_user, uso, hash del token, caducidad, fecha de uso

**`adopter`**
- Perfil del adoptante (relación 1:1 con `app_user`)
- Campos: id, id_user, nombre, apellidos, teléfono, fecha nacimiento, provincia, localidad, foto, datos del hogar (tipo y régimen de vivienda, jardín, terraza, convivientes, niños, otros animales, experiencia previa, horas que pasaría solo)

**`shelter`**
- Perfil de la protectora (relación 1:1 con `app_user`; una sola cuenta por protectora)
- Campos: id, id_user, nombre, CIF, descripción, teléfono, email de contacto, dirección completa, provincia, web, logo, horario, estado de validación, fecha de validación, motivo de rechazo

**`pet`**
- Ficha de cada mascota publicada por una protectora
- Campos: id, id_shelter, id_breed, nombre, sexo, tamaño, fecha nacimiento aproximada, nivel de actividad, convivencia con niños, descripción, salud (vacunada, desparasitada, esterilizada, microchip, necesidades especiales), tasa de adopción, estado, fecha y motivo de baja

**`pet_photo`**
- Fotos de cada mascota (máximo 6)
- Campos: id, id_pet, url, orden

**`visit_slot`**
- Turnos de visita que publica cada protectora
- Campos: id, id_shelter, fecha, hora inicio, hora fin, capacidad

**`visit`**
- Solicitudes de visita de un adoptante a una mascota en un turno
- Campos: id, id_adopter, id_pet, id_visit_slot, estado, fecha respuesta, motivo rechazo, cancelación (fecha y quién cancela), motivo anulación, registro de asistencia, corrección del administrador, visita a la que sustituye

**`adoption`**
- Solicitudes de adopción, siempre a partir de una visita realizada
- Campos: id, id_adopter, id_pet, id_visit, estado, fecha respuesta, motivo rechazo, cancelación (fecha, quién y motivo), motivo anulación, fecha entrega, devolución (fecha y motivo)

**`adopter_preference`**
- Cuestionario de preferencias del adoptante (1:1 con `adopter`)
- Campos: id, id_adopter, exige convivencia con niños

**`conversation`**
- Chat entre un adoptante y una protectora (una conversación por pareja)
- Campos: id, id_adopter, id_shelter, fecha último mensaje

**`message`**
- Mensajes de cada conversación
- Campos: id, id_conversation, emisor (adoptante o protectora), texto, imagen, fecha lectura

**`notification`**
- Avisos del sistema a los usuarios
- Campos: id, id_user, tipo, texto, fecha lectura, visita / adopción / incidencia relacionada

**`adopter_block`**
- Bloqueos de adoptantes por parte de una protectora, con historial
- Campos: id, id_shelter, id_adopter, motivo, detalle interno, fecha desbloqueo

**`suspension`**
- Suspensiones de cuentas aplicadas por el administrador, con historial
- Campos: id, id_user, motivo, detalle, fecha fin

**`incident`**
- Incidencias abiertas por adoptantes o protectoras y gestionadas por el administrador
- Campos: id, id_adopter, id_shelter, abierta por, visita / adopción relacionada, motivo, detalle, estado, fecha resolución, resolución

**`audit_log`**
- Registro de auditoría de cambios en la BD (lo rellenan triggers)
- Campos: id, id_user, tabla afectada, id registro, operación, datos anteriores, datos nuevos, timestamp

**`province`**
- Catálogo de las 52 provincias (código INE)
- Campos: id, nombre

**`species`**
- Catálogo de especies (en el MVP, perro y gato)
- Campos: id, nombre

**`breed`**
- Catálogo de razas de cada especie (incluye "Mestizo / Desconocida")
- Campos: id, id_species, nombre

#### Tablas Relacionales (Many-to-Many)

**`pet_compatibility_rel`**
- Relación entre mascotas y especies con las que convive (sí / no; sin fila = desconocido)

**`pet_rating_rel`**
- Relación entre adoptantes y mascotas: favorito o descartada (modo descubrir y galería)

**`preference_species_rel`**
- Relación entre preferencias y especies buscadas

**`preference_breed_rel`**
- Relación entre preferencias y razas buscadas

**`preference_compatibility_rel`**
- Relación entre preferencias y especies con las que la mascota debe convivir

**`preference_size` / `preference_sex` / `preference_age_range` / `preference_activity_level`**
- Atributos multivalor de las preferencias (varias respuestas por pregunta). En todas las preguntas, sin filas = "me da igual"

### Relaciones Clave

- Un **Usuario** es un **Adoptante**, una **Protectora** o un administrador (especialización 1:1)
- Una **Protectora** puede tener múltiples **Mascotas**, **Turnos de visita**, **Conversaciones** y **Bloqueos**
- Una **Mascota** puede tener hasta 6 **Fotos**, múltiples **Visitas** y **Adopciones**, y pertenece a una **Raza** (la especie se obtiene a través de la raza)
- Un **Adoptante** puede tener múltiples **Visitas**, **Adopciones**, **Valoraciones** y **Conversaciones**, y un único cuestionario de **Preferencias**
- Una **Adopción** procede siempre de una **Visita** del mismo adoptante a la misma mascota (clave foránea compuesta)
- Una **Visita** puede sustituir a otra visita anulada (relación reflexiva)
- Una **Notificación** apunta, como mucho, a una visita, una adopción o una incidencia
- Las tablas de negocio registran quién crea y modifica cada fila (`created_by`, `updated_by`)
- El **Audit Log** rastrea los cambios de las tablas principales; el backend indica el usuario de cada transacción con `SET LOCAL app.current_user_id = <id>`

### Configuración de Base de Datos

La creación de la base de datos, el contenido de cada archivo (esquema, seeds y dump), los usuarios de desarrollo y el glosario español ↔ inglés están en [`database/README.md`](../database/README.md).
