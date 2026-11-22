# Base de datos — PostgreSQL

Esquema de la plataforma de adopción de mascotas (MVP). Las reglas de negocio están en [../docs/reglas-de-negocio.md](../docs/reglas-de-negocio.md) y los casos de uso en [../docs/casos-de-uso.md](../docs/casos-de-uso.md).

## Archivos

| Archivo | Contenido |
|---|---|
| `schema.sql` | Estructura completa: tipos ENUM, tablas, claves, restricciones `CHECK`, índices, `updated_at` automático y auditoría en `audit_log` |
| `seed.sql` | **Datos maestros**, necesarios siempre (también en producción): 52 provincias, especies, razas y el usuario administrador |
| `seed_demo.sql` | **Datos de prueba**, solo para desarrollo y demostraciones. No cargar en producción. Usa fechas relativas a `now()` (los turnos futuros siempre son futuros) y desactiva la auditoría durante la carga |
| `dump.sql` | Copia completa (esquema + seeds) generada con `pg_dump` en PostgreSQL 18. Hay que regenerarla si cambian `schema.sql` o los seeds |

## Crear la base de datos

Probado en PostgreSQL 18; requiere PostgreSQL 11 o superior. Los comandos se ejecutan desde la carpeta `database/`, y los archivos en este orden.

```bash
createdb adopciones
```

```bash
psql -d adopciones -v ON_ERROR_STOP=1 -f schema.sql -f seed.sql -f seed_demo.sql
```

En producción se omite `seed_demo.sql`.

Alternativa: restaurar la copia completa en una base de datos vacía con `psql -d adopciones -f dump.sql`.

## Usuarios de desarrollo

Todos los usuarios de los seeds comparten la contraseña de desarrollo **`Adopta2026!`**, guardada como hash bcrypt. **Cambia la del administrador antes de desplegar en producción.**

| Rol | Email | Situación |
|---|---|---|
| Administrador | `admin@adopciones.test` | |
| Protectora | `huellas@protectora.test` | Validada (Valencia) |
| Protectora | `bigotes@protectora.test` | Validada (Madrid, sobre todo gatos) |
| Protectora | `patas@protectora.test` | Pendiente de validación: sus mascotas no son visibles |
| Adoptante | `lucia.martinez@correo.test` | Adoptó a Toby; visita confirmada a Kira |
| Adoptante | `javier.lopez@correo.test` | Elegido para adoptar a Luna (pendiente de entrega) |
| Adoptante | `marta.sanchez@correo.test` | No seleccionada para Luna; compite por Rocky |
| Adoptante | `pablo.romero@correo.test` | Compite por Rocky; asistencia corregida por el admin |
| Adoptante | `elena.navarro@correo.test` | Visita no asistida en Huellas: no puede visitar ni adoptar allí |
| Adoptante | `sergio.gil@correo.test` | Bloqueado por Huellas; suspensión pasada |
| Adoptante | `carmen.ruiz@correo.test` | Adoptó a Michi y lo devolvió |
| Adoptante | `diego.torres@correo.test` | Recién registrado, sin verificar el email ni datos del hogar |

Los datos de prueba usan fechas relativas al momento de cargarlos, así que los turnos "futuros" siempre son futuros. La auditoría se desactiva durante su carga.

## Ver el diagrama en ChartDB

Importa **`schema.sql`** con la opción de importar un script SQL (DDL) de PostgreSQL. ChartDB dibuja el diagrama a partir de las tablas, columnas, PK, FK y tipos; los índices y los triggers no aparecen en el diagrama.

Si ChartDB da error al leer las funciones o los bloques `DO` del final, importa solo las **secciones 1 a 9** del archivo (hasta la tabla `audit_log`), que son las que contienen las tablas.

## Auditoría: quién hizo el cambio

El trigger de auditoría lee el usuario de una variable de sesión. El backend la fija al principio de cada transacción:

```sql
BEGIN;
SET LOCAL app.current_user_id = '42';
-- ... cambios ...
COMMIT;
```

Si no se fija (procesos automáticos), `audit_log.id_user` queda a `NULL`, lo que significa "lo hizo el sistema".

## Convenciones

- Nombres en inglés, minúsculas y `snake_case`; tablas en singular.
- PK: `id integer GENERATED ALWAYS AS IDENTITY`.
- FK: prefijo `id_` (`id_user`, `id_pet`).
- Tablas puente (PK formada por dos FK): sufijo `_rel`.
- `created_at` / `updated_at` en todas las tablas con `id` propio; `created_by` / `updated_by` donde importa saber quién hizo el cambio.
- Fechas con zona horaria (`timestamptz`).
- Nunca se borran registros con historial: `ON DELETE RESTRICT` por defecto y `CASCADE` solo en entidades débiles.

## Glosario

### Tablas

| Español | Tabla |
|---|---|
| Usuario | `app_user` |
| Adoptante | `adopter` |
| Protectora | `shelter` |
| Suspensión | `suspension` |
| Provincia | `province` |
| Especie | `species` |
| Raza | `breed` |
| Mascota | `pet` |
| Foto de mascota | `pet_photo` |
| Convivencia de la mascota con otras especies | `pet_compatibility_rel` |
| Preferencias del adoptante | `adopter_preference` |
| Preferencias de especie / raza / convivencia | `preference_species_rel` / `preference_breed_rel` / `preference_compatibility_rel` |
| Preferencias de tamaño / sexo / edad / actividad | `preference_size` / `preference_sex` / `preference_age_range` / `preference_activity_level` |
| Valoración (favoritos y descartes) | `pet_rating_rel` |
| Turno de visita | `visit_slot` |
| Visita | `visit` |
| Adopción | `adoption` |
| Conversación | `conversation` |
| Mensaje | `message` |
| Notificación | `notification` |
| Bloqueo | `adopter_block` |
| Incidencia | `incident` |
| Registro de auditoría | `audit_log` |

### Estados

| Español | Valor |
|---|---|
| **Visita:** pendiente · confirmada · rechazada · cancelada · caducada · anulada · realizada · no asistida | `PENDING` · `CONFIRMED` · `REJECTED` · `CANCELLED` · `EXPIRED` · `VOIDED` · `COMPLETED` · `NO_SHOW` |
| **Adopción:** pendiente · aprobada · rechazada · no seleccionada · cancelada · anulada · completada · devuelta | `PENDING` · `APPROVED` · `REJECTED` · `NOT_SELECTED` · `CANCELLED` · `VOIDED` · `COMPLETED` · `RETURNED` |
| **Mascota:** disponible · reservada · adoptada · baja | `AVAILABLE` · `RESERVED` · `ADOPTED` · `WITHDRAWN` |
| **Valoración:** favorito · descartada | `FAVORITE` · `DISCARDED` |
| **Validación de protectora:** pendiente · validada · rechazada | `PENDING` · `VERIFIED` · `REJECTED` |
| **Incidencia:** abierta · en revisión · resuelta · descartada | `OPEN` · `IN_REVIEW` · `RESOLVED` · `DISMISSED` |

### Otros términos

| Español | Inglés |
|---|---|
| Motivo de baja: fallecimiento · traslado · tratamiento · acogida · error · otro · retirada por el administrador | `DECEASED` · `TRANSFERRED` · `MEDICAL_TREATMENT` · `FOSTER_CARE` · `ERROR` · `OTHER` · `REMOVED_BY_ADMIN` |
| Motivo de anulación: mascota reservada · adoptante bloqueado · adoptante suspendido · no asistida · turno cancelado · cuenta eliminada | `PET_RESERVED` · `ADOPTER_BLOCKED` · `ADOPTER_SUSPENDED` · `NO_SHOW` · `SLOT_CANCELLED` · `ACCOUNT_DELETED` (más los motivos de baja) |
| Convivencia: sí · no · desconocido | `YES` · `NO` · `UNKNOWN` |
| Tamaño: pequeño · mediano · grande | `SMALL` · `MEDIUM` · `LARGE` |
| Franja de edad: cachorro · joven · adulto · senior | `BABY` · `YOUNG` · `ADULT` · `SENIOR` |
| Vivienda: piso · casa · chalet · otro | `FLAT` · `HOUSE` · `DETACHED_HOUSE` · `OTHER` |
| Régimen de vivienda: propia · alquiler | `OWNED` · `RENTED` |
| Entrega de la mascota | `handed_over_at` |
| Tasa de adopción | `adoption_fee` |
