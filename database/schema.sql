-- =====================================================================
--  Plataforma de adopción de mascotas — Esquema de base de datos (MVP)
--  PostgreSQL 11 o superior (probado en PostgreSQL 18)
--
--  Contenido (los datos iniciales van aparte, en seed.sql):
--     1      Tipos ENUM
--     2 – 9  Tablas, claves y restricciones, por bloques
--    10      Índices únicos que garantizan reglas de negocio
--    11      Índices para las FK y las búsquedas frecuentes
--    12      updated_at automático
--    13      Auditoría
--
--  Convenciones:
--    · Nombres en inglés, minúsculas y snake_case; tablas en singular.
--    · PK: id integer GENERATED ALWAYS AS IDENTITY.
--    · FK: prefijo id_ (id_user, id_pet...).
--    · Tablas puente (PK = dos FK): sufijo _rel.
--    · Auditoría: created_at / updated_at en toda tabla con id propio;
--      created_by / updated_by donde importa saber quién hizo el cambio.
--    · Fechas con zona horaria (timestamptz).
--    · Nunca se borran registros con historial: ON DELETE RESTRICT por
--      defecto; CASCADE solo en entidades débiles.
--
--  Las reglas de negocio citadas (RN-XX) están en docs/reglas-de-negocio.md
-- =====================================================================

-- El archivo está en UTF-8 (tildes, ñ). En Windows, psql suele leer en WIN1252.
SET client_encoding = 'UTF8';


-- =====================================================================
--  1. TIPOS ENUM
-- =====================================================================

-- Identidad
CREATE TYPE user_role AS ENUM ('ADOPTER', 'SHELTER', 'ADMIN');

CREATE TYPE suspension_reason AS ENUM (
    'INAPPROPRIATE_BEHAVIOR', 'FALSE_INFORMATION', 'INAPPROPRIATE_CONTENT',
    'FRAUD', 'REPEATED_INCIDENTS', 'OTHER'
);

CREATE TYPE housing_type   AS ENUM ('FLAT', 'HOUSE', 'DETACHED_HOUSE', 'OTHER');
CREATE TYPE housing_tenure AS ENUM ('OWNED', 'RENTED');

CREATE TYPE shelter_verification_status AS ENUM ('PENDING', 'VERIFIED', 'REJECTED');

-- Mascotas
CREATE TYPE pet_sex        AS ENUM ('MALE', 'FEMALE');
CREATE TYPE pet_size       AS ENUM ('SMALL', 'MEDIUM', 'LARGE');
CREATE TYPE activity_level AS ENUM ('LOW', 'MEDIUM', 'HIGH');
CREATE TYPE age_range      AS ENUM ('BABY', 'YOUNG', 'ADULT', 'SENIOR');

-- Convivencia: UNKNOWN solo se usa con niños; con especies, "desconocido" = sin fila
CREATE TYPE compatibility AS ENUM ('YES', 'NO', 'UNKNOWN');

CREATE TYPE pet_status AS ENUM ('AVAILABLE', 'RESERVED', 'ADOPTED', 'WITHDRAWN');

CREATE TYPE withdrawal_reason AS ENUM (
    'DECEASED', 'TRANSFERRED', 'MEDICAL_TREATMENT', 'FOSTER_CARE',
    'ERROR', 'OTHER', 'REMOVED_BY_ADMIN'
);

CREATE TYPE rating_type AS ENUM ('FAVORITE', 'DISCARDED');

-- Proceso de adopción
CREATE TYPE visit_status AS ENUM (
    'PENDING', 'CONFIRMED', 'REJECTED', 'CANCELLED',
    'EXPIRED', 'VOIDED', 'COMPLETED', 'NO_SHOW'
);

CREATE TYPE adoption_status AS ENUM (
    'PENDING', 'APPROVED', 'REJECTED', 'NOT_SELECTED',
    'CANCELLED', 'VOIDED', 'COMPLETED', 'RETURNED'
);

-- CANCELLED = una de las partes se echa atrás (RN-173)
CREATE TYPE cancelled_by AS ENUM ('ADOPTER', 'SHELTER', 'SYSTEM');

-- VOIDED = cierre por causa externa (RN-173)
CREATE TYPE void_reason AS ENUM (
    'PET_RESERVED',
    'DECEASED', 'TRANSFERRED', 'MEDICAL_TREATMENT', 'FOSTER_CARE',
    'ERROR', 'OTHER', 'REMOVED_BY_ADMIN',
    'ADOPTER_BLOCKED', 'ADOPTER_SUSPENDED', 'NO_SHOW',
    'SLOT_CANCELLED', 'ACCOUNT_DELETED'
);

-- Comunicación y moderación
CREATE TYPE party AS ENUM ('ADOPTER', 'SHELTER');

-- Lista ampliable: añadir valores con ALTER TYPE ... ADD VALUE
CREATE TYPE notification_type AS ENUM (
    'VISIT_CONFIRMED', 'VISIT_REJECTED', 'VISIT_EXPIRED',
    'VISIT_CANCELLED', 'VISIT_VOIDED',
    'ADOPTION_APPROVED', 'ADOPTION_REJECTED', 'ADOPTION_NOT_SELECTED',
    'ADOPTION_CANCELLED', 'ADOPTION_VOIDED',
    'PET_AVAILABLE_AGAIN',
    'ADOPTION_PENDING_REMINDER', 'HANDOVER_PENDING_REMINDER',
    'ADOPTION_OVERDUE',
    'ADOPTER_BLOCKED',
    'INCIDENT_RESOLVED'
);

CREATE TYPE block_reason AS ENUM (
    'INAPPROPRIATE_BEHAVIOR', 'FALSE_INFORMATION', 'NON_COMPLIANCE', 'OTHER'
);

CREATE TYPE incident_reason AS ENUM (
    'INCORRECT_ATTENDANCE', 'INAPPROPRIATE_BEHAVIOR', 'FALSE_INFORMATION',
    'INAPPROPRIATE_CONTENT', 'UNFAIR_BLOCK', 'OTHER'
);

CREATE TYPE incident_status AS ENUM ('OPEN', 'IN_REVIEW', 'RESOLVED', 'DISMISSED');

CREATE TYPE audit_operation AS ENUM ('INSERT', 'UPDATE', 'DELETE');


-- =====================================================================
--  2. IDENTIDAD
-- =====================================================================

-- Datos de acceso comunes a todos los roles.
-- "user" es palabra reservada en PostgreSQL → app_user.
CREATE TABLE app_user (
    id              integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email           varchar(254) NOT NULL,           -- único sin distinguir mayúsculas (sección 10)
    password        varchar(255) NOT NULL,           -- 255 para que quepa cualquier hash (RN-08)
    role            user_role    NOT NULL,
    email_verified  boolean      NOT NULL DEFAULT false,
    deleted_at      timestamptz,                     -- cuenta eliminada y anonimizada (RN-11)
    created_at      timestamptz  NOT NULL DEFAULT now(),
    updated_at      timestamptz  NOT NULL DEFAULT now()
);

-- Catálogo de provincias. PK = código INE (no autoincremental).
CREATE TABLE province (
    id    smallint    PRIMARY KEY,
    name  varchar(60) NOT NULL UNIQUE
);

-- Perfil de adoptante (Usuario 1:1 Adoptante).
-- Los datos del hogar son opcionales al registrarse y obligatorios
-- para solicitar una adopción (lo valida el backend, RN-27).
-- La mayoría de edad (RN-25) la valida el backend al registrar.
CREATE TABLE adopter (
    id                   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_user              integer      NOT NULL UNIQUE REFERENCES app_user (id),
    first_name           varchar(80)  NOT NULL,
    last_name            varchar(120) NOT NULL,
    phone                varchar(20)  NOT NULL,
    birth_date           date         NOT NULL,
    id_province          smallint     NOT NULL REFERENCES province (id),
    city                 varchar(100) NOT NULL,
    profile_photo_url    varchar(500),
    -- Datos del hogar
    housing_type         housing_type,
    has_garden           boolean,
    has_terrace          boolean,
    housing_tenure       housing_tenure,
    household_members    smallint CHECK (household_members >= 1),
    has_children         boolean,
    other_pets           text,
    previous_experience  text,
    hours_alone_per_day  smallint CHECK (hours_alone_per_day BETWEEN 0 AND 24),
    created_at           timestamptz  NOT NULL DEFAULT now(),
    updated_at           timestamptz  NOT NULL DEFAULT now()
);

-- Perfil de protectora (Usuario 1:1 Protectora; una cuenta por protectora, RN-09).
CREATE TABLE shelter (
    id                   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_user              integer      NOT NULL UNIQUE REFERENCES app_user (id),
    name                 varchar(150) NOT NULL,
    cif                  varchar(9)   NOT NULL UNIQUE,
    description          text,
    phone                varchar(20)  NOT NULL,
    contact_email        varchar(254),                -- público y opcional (RN-20)
    address              varchar(200) NOT NULL,
    postal_code          char(5)      NOT NULL,
    city                 varchar(100) NOT NULL,
    id_province          smallint     NOT NULL REFERENCES province (id),
    website              varchar(300),
    logo_url             varchar(500),
    opening_hours        text,
    verification_status  shelter_verification_status NOT NULL DEFAULT 'PENDING',
    verified_at          timestamptz,
    rejection_reason     text,
    created_at           timestamptz  NOT NULL DEFAULT now(),
    updated_at           timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT chk_shelter_rejection
        CHECK (verification_status <> 'REJECTED' OR rejection_reason IS NOT NULL)
);

-- Suspensiones de cuenta con historial (Usuario 1:N Suspensión).
-- created_at = inicio; ended_at NULL = suspensión activa.
CREATE TABLE suspension (
    id          integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_user     integer           NOT NULL REFERENCES app_user (id),
    reason      suspension_reason NOT NULL,
    details     text,
    ended_at    timestamptz,
    created_at  timestamptz       NOT NULL DEFAULT now(),
    updated_at  timestamptz       NOT NULL DEFAULT now(),
    created_by  integer           REFERENCES app_user (id),
    updated_by  integer           REFERENCES app_user (id),
    CONSTRAINT chk_suspension_dates CHECK (ended_at IS NULL OR ended_at >= created_at)
);


-- =====================================================================
--  3. CATÁLOGOS
-- =====================================================================

CREATE TABLE species (
    id          integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        varchar(50) NOT NULL UNIQUE,
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now()
);

-- Cada especie tiene una raza "Mestizo / Desconocida" (RN-40).
CREATE TABLE breed (
    id          integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_species  integer      NOT NULL REFERENCES species (id),
    name        varchar(100) NOT NULL,
    created_at  timestamptz  NOT NULL DEFAULT now(),
    updated_at  timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT uq_breed_species_name UNIQUE (id_species, name)
);


-- =====================================================================
--  4. MASCOTAS
-- =====================================================================

-- La especie se obtiene a través de la raza (RN-41): no hay id_species.
-- status se guarda por rendimiento y se mantiene con transacciones (RN-174).
CREATE TABLE pet (
    id                      integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_shelter              integer        NOT NULL REFERENCES shelter (id),
    id_breed                integer        NOT NULL REFERENCES breed (id),
    name                    varchar(80)    NOT NULL,
    sex                     pet_sex        NOT NULL,
    size                    pet_size       NOT NULL,
    approx_birth_date       date           NOT NULL,   -- la franja de edad se calcula (RN-43)
    activity_level          activity_level NOT NULL,
    children_compatibility  compatibility  NOT NULL DEFAULT 'UNKNOWN',
    description             text,
    vaccinated              boolean        NOT NULL DEFAULT false,
    dewormed                boolean        NOT NULL DEFAULT false,
    neutered                boolean        NOT NULL DEFAULT false,
    microchipped            boolean        NOT NULL DEFAULT false,
    special_needs           text,
    adoption_fee            numeric(7,2)   CHECK (adoption_fee >= 0),  -- informativa (RN-48)
    status                  pet_status     NOT NULL DEFAULT 'AVAILABLE',
    withdrawn_at            timestamptz,
    withdrawal_reason       withdrawal_reason,
    created_at              timestamptz    NOT NULL DEFAULT now(),   -- = fecha de alta
    updated_at              timestamptz    NOT NULL DEFAULT now(),
    created_by              integer        REFERENCES app_user (id),
    updated_by              integer        REFERENCES app_user (id),
    -- La fecha y el motivo de baja existen solo si la mascota está de baja
    CONSTRAINT chk_pet_withdrawal CHECK (
        (status = 'WITHDRAWN') = (withdrawn_at IS NOT NULL AND withdrawal_reason IS NOT NULL)
    )
);

-- Entidad débil: CASCADE. Máximo 6 fotos: display_order 1..6 + UNIQUE (RN-50).
-- La foto con display_order = 1 es la principal (RN-51).
CREATE TABLE pet_photo (
    id             integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_pet         integer      NOT NULL REFERENCES pet (id) ON DELETE CASCADE,
    url            varchar(500) NOT NULL,
    display_order  smallint     NOT NULL CHECK (display_order BETWEEN 1 AND 6),
    created_at     timestamptz  NOT NULL DEFAULT now(),
    updated_at     timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT uq_pet_photo_order UNIQUE (id_pet, display_order)
);

-- Convivencia con otras especies (Mascota N:M Especie, con atributo).
-- Sin fila = desconocido (RN-46).
CREATE TABLE pet_compatibility_rel (
    id_pet      integer       NOT NULL REFERENCES pet (id) ON DELETE CASCADE,
    id_species  integer       NOT NULL REFERENCES species (id),
    result      compatibility NOT NULL CHECK (result <> 'UNKNOWN'),
    PRIMARY KEY (id_pet, id_species)
);


-- =====================================================================
--  5. PREFERENCIAS DEL ADOPTANTE
-- =====================================================================
--  "Me da igual" = no hay filas para esa pregunta (RN-34).

-- Adoptante 1:0..1 Preferencias. Si no existe la fila, el adoptante
-- nunca ha visto el cuestionario.
CREATE TABLE adopter_preference (
    id                               integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_adopter                       integer     NOT NULL UNIQUE REFERENCES adopter (id) ON DELETE CASCADE,
    requires_children_compatibility  boolean     NOT NULL DEFAULT false,
    created_at                       timestamptz NOT NULL DEFAULT now(),
    updated_at                       timestamptz NOT NULL DEFAULT now()
);

-- N:M con catálogos (tablas puente)
CREATE TABLE preference_species_rel (
    id_preference  integer NOT NULL REFERENCES adopter_preference (id) ON DELETE CASCADE,
    id_species     integer NOT NULL REFERENCES species (id),
    PRIMARY KEY (id_preference, id_species)
);

CREATE TABLE preference_breed_rel (
    id_preference  integer NOT NULL REFERENCES adopter_preference (id) ON DELETE CASCADE,
    id_breed       integer NOT NULL REFERENCES breed (id),
    PRIMARY KEY (id_preference, id_breed)
);

-- "Necesito que se lleve bien con..." (otra N:M con species, con otro significado)
CREATE TABLE preference_compatibility_rel (
    id_preference  integer NOT NULL REFERENCES adopter_preference (id) ON DELETE CASCADE,
    id_species     integer NOT NULL REFERENCES species (id),
    PRIMARY KEY (id_preference, id_species)
);

-- Atributos multivalorados con valores ENUM (sin _rel: no relacionan dos entidades)
CREATE TABLE preference_size (
    id_preference  integer  NOT NULL REFERENCES adopter_preference (id) ON DELETE CASCADE,
    size           pet_size NOT NULL,
    PRIMARY KEY (id_preference, size)
);

CREATE TABLE preference_sex (
    id_preference  integer NOT NULL REFERENCES adopter_preference (id) ON DELETE CASCADE,
    sex            pet_sex NOT NULL,
    PRIMARY KEY (id_preference, sex)
);

CREATE TABLE preference_age_range (
    id_preference  integer   NOT NULL REFERENCES adopter_preference (id) ON DELETE CASCADE,
    age_range      age_range NOT NULL,
    PRIMARY KEY (id_preference, age_range)
);

CREATE TABLE preference_activity_level (
    id_preference   integer        NOT NULL REFERENCES adopter_preference (id) ON DELETE CASCADE,
    activity_level  activity_level NOT NULL,
    PRIMARY KEY (id_preference, activity_level)
);

-- Favoritos y descartes (Adoptante N:M Mascota). Sin historial (RN-76):
-- una fila por pareja que se actualiza. Un descarte caduca 30 días
-- después de updated_at (RN-75).
CREATE TABLE pet_rating_rel (
    id_adopter  integer     NOT NULL REFERENCES adopter (id) ON DELETE CASCADE,
    id_pet      integer     NOT NULL REFERENCES pet (id) ON DELETE CASCADE,
    rating      rating_type NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (id_adopter, id_pet)
);


-- =====================================================================
--  6. PROCESO DE ADOPCIÓN
-- =====================================================================

-- Turnos de visita publicados por la protectora (RN-78).
-- Que la fecha no sea pasada lo valida el backend al crear (RN-84).
CREATE TABLE visit_slot (
    id          integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_shelter  integer     NOT NULL REFERENCES shelter (id),
    slot_date   date        NOT NULL,
    start_time  time        NOT NULL,
    end_time    time        NOT NULL,
    capacity    smallint    NOT NULL CHECK (capacity >= 1),
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now(),
    created_by  integer     REFERENCES app_user (id),
    updated_by  integer     REFERENCES app_user (id),
    CONSTRAINT chk_visit_slot_times CHECK (end_time > start_time)
);

-- Visita: entidad asociativa (Adoptante, Mascota, Turno).
-- created_at = fecha de la solicitud.
-- Que el turno y la mascota sean de la misma protectora lo valida el backend (RN-83).
CREATE TABLE visit (
    id                        integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_adopter                integer      NOT NULL REFERENCES adopter (id),
    id_pet                    integer      NOT NULL REFERENCES pet (id),
    id_visit_slot             integer      NOT NULL REFERENCES visit_slot (id),
    status                    visit_status NOT NULL DEFAULT 'PENDING',
    responded_at              timestamptz,
    rejection_reason          text,
    cancelled_at              timestamptz,
    cancelled_by              cancelled_by,
    void_reason               void_reason,
    attendance_recorded_at    timestamptz,
    attendance_automatic      boolean      NOT NULL DEFAULT false,  -- REALIZADA puesta por el sistema (RN-106)
    corrected_by_admin        boolean      NOT NULL DEFAULT false,  -- NO_SHOW corregido (RN-108)
    corrected_at              timestamptz,
    id_replaced_visit         integer      REFERENCES visit (id),   -- reflexiva: visita anulada a la que sustituye (RN-111)
    created_at                timestamptz  NOT NULL DEFAULT now(),
    updated_at                timestamptz  NOT NULL DEFAULT now(),
    created_by                integer      REFERENCES app_user (id),
    updated_by                integer      REFERENCES app_user (id),
    -- Destino de la FK compuesta de adoption (garantiza adoptante y mascota coherentes)
    CONSTRAINT uq_visit_adopter_pet UNIQUE (id, id_adopter, id_pet),
    -- Quién cancela: solo si está cancelada, y nunca el sistema (RN-101, RN-173)
    CONSTRAINT chk_visit_cancelled CHECK (
        (status = 'CANCELLED') = (cancelled_by IS NOT NULL)
        AND (cancelled_by IS NULL OR cancelled_by <> 'SYSTEM')
    ),
    -- Motivo de anulación: solo si está anulada
    CONSTRAINT chk_visit_voided CHECK ((status = 'VOIDED') = (void_reason IS NOT NULL)),
    CONSTRAINT chk_visit_correction CHECK (NOT corrected_by_admin OR corrected_at IS NOT NULL),
    CONSTRAINT chk_visit_not_self_replaced CHECK (id_replaced_visit <> id)
);

-- Adopción. created_at = fecha de la solicitud.
-- id_adopter e id_pet se deducen de la visita, pero se guardan porque los
-- índices únicos parciales R1 y R2 los necesitan en esta tabla.
-- La FK compuesta garantiza que coinciden con los de la visita.
CREATE TABLE adoption (
    id                   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_adopter           integer         NOT NULL REFERENCES adopter (id),
    id_pet               integer         NOT NULL REFERENCES pet (id),
    id_visit             integer         NOT NULL,
    status               adoption_status NOT NULL DEFAULT 'PENDING',
    responded_at         timestamptz,
    rejection_reason     text,
    cancelled_at         timestamptz,
    cancelled_by         cancelled_by,
    cancellation_reason  text,
    void_reason          void_reason,
    handed_over_at       timestamptz,     -- entrega de la mascota (RN-126)
    returned_at          timestamptz,
    return_reason        text,
    created_at           timestamptz     NOT NULL DEFAULT now(),
    updated_at           timestamptz     NOT NULL DEFAULT now(),
    created_by           integer         REFERENCES app_user (id),
    updated_by           integer         REFERENCES app_user (id),
    CONSTRAINT fk_adoption_visit
        FOREIGN KEY (id_visit, id_adopter, id_pet)
        REFERENCES visit (id, id_adopter, id_pet),
    CONSTRAINT chk_adoption_cancelled CHECK ((status = 'CANCELLED') = (cancelled_by IS NOT NULL)),
    CONSTRAINT chk_adoption_voided    CHECK ((status = 'VOIDED')    = (void_reason IS NOT NULL)),
    CONSTRAINT chk_adoption_handover  CHECK ((status IN ('COMPLETED', 'RETURNED')) = (handed_over_at IS NOT NULL)),
    CONSTRAINT chk_adoption_returned  CHECK ((status = 'RETURNED') = (returned_at IS NOT NULL))
);


-- =====================================================================
--  7. COMUNICACIÓN
-- =====================================================================

-- Una conversación por pareja adoptante–protectora (RN-133).
CREATE TABLE conversation (
    id               integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_adopter       integer     NOT NULL REFERENCES adopter (id),
    id_shelter       integer     NOT NULL REFERENCES shelter (id),
    last_message_at  timestamptz,      -- desnormalizado para ordenar la bandeja
    created_at       timestamptz NOT NULL DEFAULT now(),
    updated_at       timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_conversation_pair UNIQUE (id_adopter, id_shelter)
);

-- El emisor es un lado de la conversación, no un usuario.
-- created_at = fecha de envío.
CREATE TABLE message (
    id               integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_conversation  integer     NOT NULL REFERENCES conversation (id),
    sender           party       NOT NULL,
    body             text,
    image_url        varchar(500),
    read_at          timestamptz,
    created_at       timestamptz NOT NULL DEFAULT now(),
    updated_at       timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT chk_message_content CHECK (body IS NOT NULL OR image_url IS NOT NULL)
);


-- =====================================================================
--  8. MODERACIÓN
-- =====================================================================

-- Bloqueo de un adoptante por una protectora, con historial.
-- created_at = fecha de bloqueo; unblocked_at NULL = bloqueo activo.
CREATE TABLE adopter_block (
    id            integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_shelter    integer      NOT NULL REFERENCES shelter (id),
    id_adopter    integer      NOT NULL REFERENCES adopter (id),
    reason        block_reason NOT NULL,
    details       text,                -- interno, el adoptante no lo ve
    unblocked_at  timestamptz,
    created_at    timestamptz  NOT NULL DEFAULT now(),
    updated_at    timestamptz  NOT NULL DEFAULT now(),
    created_by    integer      REFERENCES app_user (id),
    updated_by    integer      REFERENCES app_user (id),
    CONSTRAINT chk_block_dates CHECK (unblocked_at IS NULL OR unblocked_at >= created_at)
);

-- Incidencia entre un adoptante y una protectora, en los dos sentidos.
-- Arco exclusivo: como mucho una visita o una adopción.
CREATE TABLE incident (
    id           integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_adopter   integer         NOT NULL REFERENCES adopter (id),
    id_shelter   integer         NOT NULL REFERENCES shelter (id),
    opened_by    party           NOT NULL,
    id_visit     integer         REFERENCES visit (id),
    id_adoption  integer         REFERENCES adoption (id),
    reason       incident_reason NOT NULL,
    details      text            NOT NULL,
    status       incident_status NOT NULL DEFAULT 'OPEN',
    resolved_at  timestamptz,
    resolution   text,
    created_at   timestamptz     NOT NULL DEFAULT now(),
    updated_at   timestamptz     NOT NULL DEFAULT now(),
    created_by   integer         REFERENCES app_user (id),
    updated_by   integer         REFERENCES app_user (id),
    CONSTRAINT chk_incident_single_link CHECK (num_nonnulls(id_visit, id_adoption) <= 1),
    CONSTRAINT chk_incident_resolved CHECK (
        (status IN ('RESOLVED', 'DISMISSED')) = (resolved_at IS NOT NULL)
    )
);

-- Notificaciones para cualquier rol. Arco exclusivo: como mucho un enlace.
CREATE TABLE notification (
    id           integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_user      integer           NOT NULL REFERENCES app_user (id),
    type         notification_type NOT NULL,
    body         text              NOT NULL,
    read_at      timestamptz,
    id_visit     integer           REFERENCES visit (id),
    id_adoption  integer           REFERENCES adoption (id),
    id_incident  integer           REFERENCES incident (id),
    created_at   timestamptz       NOT NULL DEFAULT now(),
    updated_at   timestamptz       NOT NULL DEFAULT now(),
    CONSTRAINT chk_notification_single_link
        CHECK (num_nonnulls(id_visit, id_adoption, id_incident) <= 1)
);


-- =====================================================================
--  9. AUDITORÍA
-- =====================================================================

-- Registro de cambios de las tablas principales (lo rellenan los triggers de la sección 13).
-- id_user = quién hizo el cambio (NULL si fue el sistema).
CREATE TABLE audit_log (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_user     integer         REFERENCES app_user (id),
    table_name  varchar(63)     NOT NULL,
    id_record   integer         NOT NULL,
    operation   audit_operation NOT NULL,
    old_data    jsonb,
    new_data    jsonb,
    logged_at   timestamptz     NOT NULL DEFAULT now()
);


-- =====================================================================
--  10. ÍNDICES ÚNICOS (reglas de negocio)
-- =====================================================================

-- Email único sin distinguir mayúsculas ("Ana@x.com" = "ana@x.com") (RN-06)
CREATE UNIQUE INDEX uq_app_user_email ON app_user (lower(email));

-- Una sola suspensión activa por usuario
CREATE UNIQUE INDEX uq_suspension_active
    ON suspension (id_user)
    WHERE ended_at IS NULL;

-- Una sola visita activa por mascota y turno (RN-81).
-- Las visitas canceladas, rechazadas, caducadas o anuladas no bloquean la plaza.
CREATE UNIQUE INDEX uq_visit_active_slot_pet
    ON visit (id_visit_slot, id_pet)
    WHERE status IN ('PENDING', 'CONFIRMED', 'COMPLETED', 'NO_SHOW');

-- R1: una sola adopción aprobada o completada por mascota
CREATE UNIQUE INDEX uq_adoption_active_pet
    ON adoption (id_pet)
    WHERE status IN ('APPROVED', 'COMPLETED');

-- R2: una sola solicitud abierta por adoptante y mascota
CREATE UNIQUE INDEX uq_adoption_open_adopter_pet
    ON adoption (id_adopter, id_pet)
    WHERE status IN ('PENDING', 'APPROVED');

-- Un solo bloqueo activo por pareja protectora–adoptante
CREATE UNIQUE INDEX uq_adopter_block_active
    ON adopter_block (id_shelter, id_adopter)
    WHERE unblocked_at IS NULL;


-- =====================================================================
--  11. ÍNDICES PARA FK Y BÚSQUEDAS
-- =====================================================================
--  PostgreSQL crea índices automáticamente para PK y UNIQUE, pero NO
--  para las FK: se crean aquí los de las FK y búsquedas más frecuentes.

-- Identidad
CREATE INDEX ix_adopter_province   ON adopter (id_province);
CREATE INDEX ix_shelter_province   ON shelter (id_province);
CREATE INDEX ix_shelter_status     ON shelter (verification_status);
CREATE INDEX ix_suspension_user    ON suspension (id_user);

-- Mascotas: la galería y el modo descubrir filtran siempre por estado
CREATE INDEX ix_pet_shelter        ON pet (id_shelter);
CREATE INDEX ix_pet_breed          ON pet (id_breed);
CREATE INDEX ix_pet_status         ON pet (status);

-- Las PK compuestas ya indexan su primera columna; se añade la segunda
CREATE INDEX ix_pet_rating_pet     ON pet_rating_rel (id_pet);

-- Proceso de adopción
CREATE INDEX ix_visit_slot_shelter_date ON visit_slot (id_shelter, slot_date);
CREATE INDEX ix_visit_adopter      ON visit (id_adopter);
CREATE INDEX ix_visit_pet          ON visit (id_pet);
CREATE INDEX ix_visit_slot         ON visit (id_visit_slot);
CREATE INDEX ix_visit_status       ON visit (status);
CREATE INDEX ix_adoption_adopter   ON adoption (id_adopter);
CREATE INDEX ix_adoption_pet       ON adoption (id_pet);
CREATE INDEX ix_adoption_visit     ON adoption (id_visit);
CREATE INDEX ix_adoption_status    ON adoption (status);

-- Comunicación
CREATE INDEX ix_conversation_shelter       ON conversation (id_shelter);
CREATE INDEX ix_message_conversation_date  ON message (id_conversation, created_at);
CREATE INDEX ix_notification_user_date     ON notification (id_user, created_at DESC);

-- Moderación
CREATE INDEX ix_adopter_block_adopter ON adopter_block (id_adopter);
CREATE INDEX ix_incident_adopter      ON incident (id_adopter);
CREATE INDEX ix_incident_shelter      ON incident (id_shelter);
CREATE INDEX ix_incident_status       ON incident (status);

-- Auditoría: historial de un registro concreto
CREATE INDEX ix_audit_log_record ON audit_log (table_name, id_record);


-- =====================================================================
--  12. updated_at AUTOMÁTICO
-- =====================================================================

CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

-- Crea el trigger en cada tabla del esquema public que tenga columna updated_at
DO $$
DECLARE
    t record;
BEGIN
    FOR t IN
        SELECT table_name
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND column_name  = 'updated_at'
    LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_%1$s_updated_at
                 BEFORE UPDATE ON %1$I
                 FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at()',
            t.table_name
        );
    END LOOP;
END;
$$;


-- =====================================================================
--  13. AUDITORÍA
-- =====================================================================
--  ¿Quién hizo el cambio? El backend lo indica al principio de cada
--  transacción, y el trigger lo lee:
--
--      BEGIN;
--      SET LOCAL app.current_user_id = '42';
--      UPDATE pet SET ... ;
--      COMMIT;
--
--  Si no se indica (por ejemplo, en los procesos automáticos), id_user
--  queda a NULL, lo que significa "lo hizo el sistema".
--
--  La contraseña nunca se copia al registro de auditoría.
--
--  Para cargas masivas (el seed de prueba) se puede desactivar la
--  auditoría dentro de una transacción con: SET LOCAL app.skip_audit = 'on';

CREATE OR REPLACE FUNCTION fn_audit()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_user  integer := NULLIF(current_setting('app.current_user_id', true), '')::integer;
    v_old   jsonb;
    v_new   jsonb;
BEGIN
    -- Cargas masivas (seed de prueba): SET LOCAL app.skip_audit = 'on'
    IF current_setting('app.skip_audit', true) = 'on' THEN
        RETURN COALESCE(NEW, OLD);
    END IF;

    IF TG_OP IN ('UPDATE', 'DELETE') THEN
        v_old := to_jsonb(OLD) - 'password';
    END IF;
    IF TG_OP IN ('INSERT', 'UPDATE') THEN
        v_new := to_jsonb(NEW) - 'password';
    END IF;

    -- Un UPDATE que no cambia nada no se registra
    IF TG_OP = 'UPDATE' AND v_old = v_new THEN
        RETURN NEW;
    END IF;

    INSERT INTO audit_log (id_user, table_name, id_record, operation, old_data, new_data)
    VALUES (
        v_user,
        TG_TABLE_NAME,
        (COALESCE(v_new, v_old)->>'id')::integer,
        TG_OP::audit_operation,
        v_old,
        v_new
    );

    RETURN COALESCE(NEW, OLD);
END;
$$;

-- Tablas auditadas: las que reflejan decisiones del proceso o de moderación.
-- No se auditan mensajes ni notificaciones (mucho volumen y poco valor)
-- ni las tablas puente.
DO $$
DECLARE
    t text;
BEGIN
    FOREACH t IN ARRAY ARRAY[
        'app_user', 'adopter', 'shelter', 'suspension',
        'pet', 'visit_slot', 'visit', 'adoption',
        'adopter_block', 'incident'
    ]
    LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_%1$s_audit
                 AFTER INSERT OR UPDATE OR DELETE ON %1$I
                 FOR EACH ROW EXECUTE FUNCTION fn_audit()',
            t
        );
    END LOOP;
END;
$$;
