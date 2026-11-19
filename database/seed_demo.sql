-- =====================================================================
--  Plataforma de adopción de mascotas — Datos de prueba (demo)
--  Ejecutar después de schema.sql y seed.sql
--
--  SOLO para desarrollo y demostraciones: no cargar en producción.
--
--  · Fechas relativas al momento de ejecutarlo (now(), current_date):
--    los turnos "futuros" siempre son futuros.
--  · Auditoría desactivada durante la carga (app.skip_audit).
--  · Todos los usuarios comparten la contraseña de desarrollo indicada
--    en database/README.md.
--
--  Reparto de usuarios (app_user.id):
--     1      admin (seed.sql)
--     2–4    protectoras  → shelter.id 1–3
--     5–12   adoptantes   → adopter.id 1–8  (adopter.id = app_user.id − 4)
--
--  Escenarios que cubre:
--    · Protectoras validadas y una pendiente de validación (sus mascotas no son visibles).
--    · Mascotas disponibles, reservada, adoptada, devuelta y de baja.
--    · Visitas en todos los estados, incluida una corregida por el admin
--      y una que sustituye a otra anulada por cambio de turno.
--    · Dos candidatos compitiendo por la misma mascota, un no seleccionado,
--      una adopción aprobada pendiente de entrega, completada, devuelta y cancelada.
--    · Preferencias, favoritos y descartes (uno ya caducado).
--    · Conversaciones, notificaciones, bloqueos, una suspensión pasada
--      e incidencias abiertas, en revisión y resueltas.
-- =====================================================================

-- El archivo está en UTF-8 (tildes, ñ). En Windows, psql suele leer en WIN1252.
SET client_encoding = 'UTF8';

BEGIN;
SET LOCAL app.skip_audit = 'on';


-- =====================================================================
--  1. USUARIOS
-- =====================================================================

INSERT INTO app_user (id, email, password, role, email_verified, created_at, updated_at) OVERRIDING SYSTEM VALUE VALUES
    -- Protectoras
    ( 2, 'huellas@protectora.test', '$2a$10$2Dq0w6NRTOID2G1xporNUO2ZG2e3qYOzHmDdzmwk89UymFC5YUJAi', 'SHELTER', true,  now() - interval '120 days', now() - interval '120 days'),
    ( 3, 'bigotes@protectora.test', '$2a$10$2Dq0w6NRTOID2G1xporNUO2ZG2e3qYOzHmDdzmwk89UymFC5YUJAi', 'SHELTER', true,  now() - interval '150 days', now() - interval '150 days'),
    ( 4, 'patas@protectora.test',   '$2a$10$2Dq0w6NRTOID2G1xporNUO2ZG2e3qYOzHmDdzmwk89UymFC5YUJAi', 'SHELTER', true,  now() - interval '5 days',   now() - interval '5 days'),
    -- Adoptantes
    ( 5, 'lucia.martinez@correo.test', '$2a$10$2Dq0w6NRTOID2G1xporNUO2ZG2e3qYOzHmDdzmwk89UymFC5YUJAi', 'ADOPTER', true,  now() - interval '90 days', now() - interval '90 days'),
    ( 6, 'javier.lopez@correo.test',   '$2a$10$2Dq0w6NRTOID2G1xporNUO2ZG2e3qYOzHmDdzmwk89UymFC5YUJAi', 'ADOPTER', true,  now() - interval '60 days', now() - interval '60 days'),
    ( 7, 'marta.sanchez@correo.test',  '$2a$10$2Dq0w6NRTOID2G1xporNUO2ZG2e3qYOzHmDdzmwk89UymFC5YUJAi', 'ADOPTER', true,  now() - interval '45 days', now() - interval '45 days'),
    ( 8, 'pablo.romero@correo.test',   '$2a$10$2Dq0w6NRTOID2G1xporNUO2ZG2e3qYOzHmDdzmwk89UymFC5YUJAi', 'ADOPTER', true,  now() - interval '40 days', now() - interval '40 days'),
    ( 9, 'elena.navarro@correo.test',  '$2a$10$2Dq0w6NRTOID2G1xporNUO2ZG2e3qYOzHmDdzmwk89UymFC5YUJAi', 'ADOPTER', true,  now() - interval '30 days', now() - interval '30 days'),
    (10, 'sergio.gil@correo.test',     '$2a$10$2Dq0w6NRTOID2G1xporNUO2ZG2e3qYOzHmDdzmwk89UymFC5YUJAi', 'ADOPTER', true,  now() - interval '80 days', now() - interval '80 days'),
    (11, 'carmen.ruiz@correo.test',    '$2a$10$2Dq0w6NRTOID2G1xporNUO2ZG2e3qYOzHmDdzmwk89UymFC5YUJAi', 'ADOPTER', true,  now() - interval '70 days', now() - interval '70 days'),
    -- Recién registrado: sin verificar el email, sin datos del hogar ni preferencias
    (12, 'diego.torres@correo.test',   '$2a$10$2Dq0w6NRTOID2G1xporNUO2ZG2e3qYOzHmDdzmwk89UymFC5YUJAi', 'ADOPTER', false, now() - interval '1 hour',  now() - interval '1 hour');


-- =====================================================================
--  2. PROTECTORAS
-- =====================================================================

INSERT INTO shelter (id, id_user, name, cif, description, phone, contact_email, address, postal_code, city, id_province,
                     website, logo_url, opening_hours, verification_status, verified_at, created_at, updated_at)
OVERRIDING SYSTEM VALUE VALUES
    (1, 2, 'Protectora Huellas de Valencia', 'G46123456',
        'Rescatamos perros y gatos abandonados en la comarca de L''Horta desde 2012.',
        '961000001', 'info@huellasvalencia.test', 'Camí del Riu, 15', '46019', 'Valencia', 46,
        'https://huellasvalencia.test', '/uploads/shelters/1.png', 'Lunes a sábado, de 10:00 a 13:00 y de 17:00 a 19:00',
        'VERIFIED', now() - interval '118 days', now() - interval '120 days', now() - interval '118 days'),
    (2, 3, 'Asociación Bigotes Libres', 'G28123456',
        'Asociación felina con colonias controladas y casas de acogida en Madrid.',
        '911000002', 'hola@bigoteslibres.test', 'Calle del Gato, 7', '28045', 'Madrid', 28,
        NULL, '/uploads/shelters/2.png', 'Visitas con cita previa',
        'VERIFIED', now() - interval '148 days', now() - interval '150 days', now() - interval '148 days'),
    -- Pendiente de validación: sus mascotas no son visibles (RN-22)
    (3, 4, 'Refugio Patas Nuevas', 'G03123456',
        'Refugio recién creado en la Vega Baja.',
        '965000003', NULL, 'Partida La Matanza, s/n', '03300', 'Orihuela', 3,
        NULL, NULL, NULL,
        'PENDING', NULL, now() - interval '5 days', now() - interval '5 days');


-- =====================================================================
--  3. ADOPTANTES
-- =====================================================================

INSERT INTO adopter (id, id_user, first_name, last_name, phone, birth_date, id_province, city, profile_photo_url,
                     housing_type, has_garden, has_terrace, housing_tenure, household_members, has_children,
                     other_pets, previous_experience, hours_alone_per_day, created_at, updated_at)
OVERRIDING SYSTEM VALUE VALUES
    (1,  5, 'Lucía',  'Martínez Soler', '600000001', '1988-04-12', 46, 'Valencia',  '/uploads/adopters/1.jpg',
        'HOUSE', true, false, 'OWNED', 4, true, 'Una gata de 6 años, esterilizada.', 'He tenido perros toda la vida.', 4,
        now() - interval '90 days', now() - interval '89 days'),
    (2,  6, 'Javier', 'López Ferrer',   '600000002', '1992-09-30', 46, 'Paterna',   NULL,
        'FLAT', false, true, 'RENTED', 2, false, NULL, 'Primera vez que adopto.', 6,
        now() - interval '60 days', now() - interval '59 days'),
    (3,  7, 'Marta',  'Sánchez Vidal',  '600000003', '1985-01-22', 46, 'Burjassot', NULL,
        'DETACHED_HOUSE', true, true, 'OWNED', 3, true, NULL, 'Fui casa de acogida de dos podencos.', 3,
        now() - interval '45 days', now() - interval '44 days'),
    (4,  8, 'Pablo',  'Romero Gil',     '600000004', '1979-06-03', 28, 'Getafe',    NULL,
        'FLAT', false, false, 'OWNED', 1, false, NULL, 'Tuve un beagle durante 12 años.', 8,
        now() - interval '40 days', now() - interval '39 days'),
    (5,  9, 'Elena',  'Navarro Pons',   '600000005', '1995-11-15', 46, 'Valencia',  NULL,
        'FLAT', false, true, 'RENTED', 2, false, NULL, NULL, 5,
        now() - interval '30 days', now() - interval '29 days'),
    (6, 10, 'Sergio', 'Gil Andrés',     '600000006', '1990-02-08', 46, 'Mislata',   NULL,
        'HOUSE', true, false, 'OWNED', 2, false, 'Un perro mestizo.', 'Siempre he tenido perros.', 6,
        now() - interval '80 days', now() - interval '79 days'),
    (7, 11, 'Carmen', 'Ruiz Blasco',    '600000007', '1968-07-19', 28, 'Madrid',    NULL,
        'FLAT', false, true, 'OWNED', 2, false, NULL, 'He tenido gatos.', 4,
        now() - interval '70 days', now() - interval '69 days'),
    -- Sin datos del hogar: aún no puede solicitar adopciones (RN-27)
    (8, 12, 'Diego',  'Torres Mena',    '600000008', '2001-03-27', 50, 'Zaragoza',  NULL,
        NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        now() - interval '1 hour', now() - interval '1 hour');


-- =====================================================================
--  4. SUSPENSIONES (historial)
-- =====================================================================

-- Sergio fue suspendido hace dos meses durante 15 días (ya terminada)
INSERT INTO suspension (id_user, reason, details, ended_at, created_at, updated_at, created_by, updated_by) VALUES
    (10, 'INAPPROPRIATE_BEHAVIOR', 'Varias incidencias por mensajes ofensivos.',
        now() - interval '45 days', now() - interval '60 days', now() - interval '45 days', 1, 1);


-- =====================================================================
--  5. MASCOTAS
-- =====================================================================
--  Razas (seed.sql): 1 perro mestizo · 2 Labrador · 4 Pastor Alemán · 6 Podenco Andaluz
--  8 Galgo · 9 Bodeguero · 10 Mastín · 11 Border Collie · 12 Beagle · 14 American Staffordshire
--  16 Yorkshire · 17 Chihuahua · 23 gato mestizo · 24 Común Europeo · 25 Siamés · 26 Persa
--  29 Bengalí · 30 Ragdoll · 32 Angora Turco

INSERT INTO pet (id, id_shelter, id_breed, name, sex, size, approx_birth_date, activity_level, children_compatibility,
                 description, vaccinated, dewormed, neutered, microchipped, special_needs, adoption_fee,
                 status, withdrawn_at, withdrawal_reason, created_at, updated_at, created_by, updated_by)
OVERRIDING SYSTEM VALUE VALUES
    -- ---- Protectora Huellas de Valencia (shelter 1, usuario 2) ----
    ( 1, 1,  2, 'Toby',  'MALE',   'LARGE',  (current_date - interval '4 years')::date,  'HIGH',   'YES',
        'Labrador cariñoso y juguetón. Adoptado.', true, true, true, true, NULL, 150.00,
        'ADOPTED',   NULL, NULL, now() - interval '60 days', now() - interval '21 days', 2, 2),
    ( 2, 1,  1, 'Luna',  'FEMALE', 'MEDIUM', (current_date - interval '2 years')::date,  'MEDIUM', 'YES',
        'Mestiza muy sociable con personas y animales.', true, true, true, true, NULL, 150.00,
        'RESERVED',  NULL, NULL, now() - interval '45 days', now() - interval '2 days', 2, 2),
    ( 3, 1,  6, 'Rocky', 'MALE',   'MEDIUM', (current_date - interval '3 years')::date,  'HIGH',   'UNKNOWN',
        'Podenco rescatado de una rehala. Necesita correr cada día.', true, true, true, true, NULL, 150.00,
        'AVAILABLE', NULL, NULL, now() - interval '40 days', now() - interval '40 days', 2, 2),
    ( 4, 1,  8, 'Nala',  'FEMALE', 'LARGE',  (current_date - interval '5 years')::date,  'LOW',    'YES',
        'Galga tranquila, ideal para un hogar sosegado.', true, true, true, true, NULL, 150.00,
        'AVAILABLE', NULL, NULL, now() - interval '35 days', now() - interval '35 days', 2, 2),
    ( 5, 1,  9, 'Coco',  'MALE',   'SMALL',  (current_date - interval '1 year')::date,   'HIGH',   'YES',
        'Bodeguero joven con mucha energía.', true, true, false, true, NULL, 120.00,
        'AVAILABLE', NULL, NULL, now() - interval '30 days', now() - interval '30 days', 2, 2),
    ( 6, 1,  4, 'Max',   'MALE',   'LARGE',  (current_date - interval '6 years')::date,  'MEDIUM', 'NO',
        'Pastor alemán protector; mejor sin niños pequeños ni otros animales.', true, true, true, true, NULL, 150.00,
        'AVAILABLE', NULL, NULL, now() - interval '28 days', now() - interval '28 days', 2, 2),
    ( 7, 1, 11, 'Kira',  'FEMALE', 'MEDIUM', (current_date - interval '2 years')::date,  'HIGH',   'YES',
        'Border collie muy lista; le encanta aprender trucos.', true, true, true, true, NULL, 150.00,
        'AVAILABLE', NULL, NULL, now() - interval '25 days', now() - interval '25 days', 2, 2),
    ( 8, 1, 10, 'Thor',  'MALE',   'LARGE',  (current_date - interval '7 years')::date,  'LOW',    'YES',
        'Mastín noble y tranquilo.', true, true, true, true, 'Displasia de cadera en tratamiento.', 150.00,
        'WITHDRAWN', now() - interval '2 days', 'MEDICAL_TREATMENT', now() - interval '22 days', now() - interval '2 days', 2, 2),
    ( 9, 1, 16, 'Lola',  'FEMALE', 'SMALL',  (current_date - interval '9 years')::date,  'LOW',    'UNKNOWN',
        'Yorkshire senior que busca un sofá donde descansar.', true, true, true, true, 'Necesita pienso renal.', 80.00,
        'AVAILABLE', NULL, NULL, now() - interval '20 days', now() - interval '20 days', 2, 2),
    (10, 1, 14, 'Bruno', 'MALE',   'MEDIUM', (current_date - interval '4 years')::date,  'MEDIUM', 'YES',
        'Amstaff bonachón, muy apegado a las personas.', true, true, true, true, NULL, 150.00,
        'AVAILABLE', NULL, NULL, now() - interval '18 days', now() - interval '18 days', 2, 2),
    (11, 1, 24, 'Misi',  'FEMALE', 'SMALL',  (current_date - interval '3 years')::date,  'LOW',    'YES',
        'Gata tranquila que convive con perros.', true, true, true, true, NULL, 60.00,
        'AVAILABLE', NULL, NULL, now() - interval '15 days', now() - interval '15 days', 2, 2),
    (12, 1, 23, 'Simba', 'MALE',   'SMALL',  (current_date - interval '4 months')::date, 'HIGH',   'UNKNOWN',
        'Gatito de cuatro meses, curioso y juguetón.', true, true, false, false, NULL, NULL,
        'AVAILABLE', NULL, NULL, now() - interval '7 days',  now() - interval '7 days',  2, 2),
    -- ---- Asociación Bigotes Libres (shelter 2, usuario 3) ----
    (13, 2, 24, 'Michi',    'MALE',   'SMALL',  (current_date - interval '2 years')::date, 'MEDIUM', 'YES',
        'Volvió a la asociación tras una adopción que no salió bien.', true, true, true, true, NULL, 80.00,
        'AVAILABLE', NULL, NULL, now() - interval '70 days', now() - interval '5 days', 3, 3),
    (14, 2, 26, 'Garfield', 'MALE',   'MEDIUM', (current_date - interval '8 years')::date, 'LOW',    'YES',
        'Persa dormilón y muy mimoso.', true, true, true, true, 'Cepillado diario.', 80.00,
        'AVAILABLE', NULL, NULL, now() - interval '50 days', now() - interval '50 days', 3, 3),
    (15, 2, 23, 'Salem',    'MALE',   'SMALL',  (current_date - interval '1 year')::date,  'HIGH',   'UNKNOWN',
        'Gato negro rescatado de una colonia.', true, true, true, true, NULL, 80.00,
        'AVAILABLE', NULL, NULL, now() - interval '30 days', now() - interval '30 days', 3, 3),
    (16, 2, 32, 'Nube',     'FEMALE', 'SMALL',  (current_date - interval '3 years')::date, 'LOW',    'YES',
        'Angora blanca, tímida al principio.', true, true, true, true, NULL, 80.00,
        'AVAILABLE', NULL, NULL, now() - interval '26 days', now() - interval '26 days', 3, 3),
    (17, 2, 29, 'Tigre',    'MALE',   'MEDIUM', (current_date - interval '2 years')::date, 'HIGH',   'NO',
        'Bengalí muy activo; mejor como único gato.', true, true, true, true, NULL, 100.00,
        'AVAILABLE', NULL, NULL, now() - interval '22 days', now() - interval '22 days', 3, 3),
    (18, 2, 30, 'Pelusa',   'FEMALE', 'MEDIUM', (current_date - interval '5 years')::date, 'LOW',    'YES',
        'Ragdoll muy dócil.', true, true, true, true, NULL, 80.00,
        'WITHDRAWN', now() - interval '6 days', 'FOSTER_CARE', now() - interval '40 days', now() - interval '6 days', 3, 3),
    (19, 2, 25, 'Oliver',   'MALE',   'SMALL',  (current_date - interval '6 years')::date, 'MEDIUM', 'YES',
        'Siamés hablador y sociable.', true, true, true, true, NULL, 80.00,
        'AVAILABLE', NULL, NULL, now() - interval '12 days', now() - interval '12 days', 3, 3),
    (20, 2, 12, 'Canela',   'FEMALE', 'MEDIUM', (current_date - interval '3 years')::date, 'HIGH',   'YES',
        'Beagle rescatada de un laboratorio.', true, true, true, true, NULL, 150.00,
        'AVAILABLE', NULL, NULL, now() - interval '20 days', now() - interval '20 days', 3, 3),
    (21, 2, 17, 'Chispa',   'FEMALE', 'SMALL',  (current_date - interval '10 years')::date, 'LOW',   'NO',
        'Chihuahua senior que busca un hogar tranquilo sin niños.', true, true, true, true, NULL, 50.00,
        'AVAILABLE', NULL, NULL, now() - interval '10 days', now() - interval '10 days', 3, 3),
    -- ---- Refugio Patas Nuevas (shelter 3, pendiente de validación) ----
    (22, 3,  1, 'Duque', 'MALE',   'LARGE', (current_date - interval '3 years')::date, 'MEDIUM', 'UNKNOWN',
        'Mestizo grande y tranquilo.', true, false, false, true, NULL, NULL,
        'AVAILABLE', NULL, NULL, now() - interval '4 days', now() - interval '4 days', 4, 4),
    (23, 3, 23, 'Perla', 'FEMALE', 'SMALL', (current_date - interval '2 years')::date, 'LOW',    'UNKNOWN',
        'Gata rescatada en la calle.', true, false, true, false, NULL, NULL,
        'AVAILABLE', NULL, NULL, now() - interval '4 days', now() - interval '4 days', 4, 4),
    (24, 3,  8, 'Rayo',  'MALE',   'LARGE', (current_date - interval '4 years')::date, 'LOW',    'YES',
        'Galgo recuperado tras la temporada de caza.', true, true, true, true, NULL, NULL,
        'AVAILABLE', NULL, NULL, now() - interval '3 days', now() - interval '3 days', 4, 4),
    (25, 3, 24, 'Mora',  'FEMALE', 'SMALL', (current_date - interval '1 year')::date,  'MEDIUM', 'UNKNOWN',
        'Gata joven y cariñosa.', true, false, false, false, NULL, NULL,
        'AVAILABLE', NULL, NULL, now() - interval '3 days', now() - interval '3 days', 4, 4);


-- Fotos: la de display_order = 1 es la principal (RN-51)
INSERT INTO pet_photo (id_pet, url, display_order) VALUES
    ( 1, '/uploads/pets/1-1.jpg', 1), ( 1, '/uploads/pets/1-2.jpg', 2),
    ( 2, '/uploads/pets/2-1.jpg', 1), ( 2, '/uploads/pets/2-2.jpg', 2), ( 2, '/uploads/pets/2-3.jpg', 3),
    ( 3, '/uploads/pets/3-1.jpg', 1), ( 3, '/uploads/pets/3-2.jpg', 2),
    ( 4, '/uploads/pets/4-1.jpg', 1),
    ( 5, '/uploads/pets/5-1.jpg', 1), ( 5, '/uploads/pets/5-2.jpg', 2),
    ( 6, '/uploads/pets/6-1.jpg', 1),
    ( 7, '/uploads/pets/7-1.jpg', 1), ( 7, '/uploads/pets/7-2.jpg', 2), ( 7, '/uploads/pets/7-3.jpg', 3),
    ( 8, '/uploads/pets/8-1.jpg', 1),
    ( 9, '/uploads/pets/9-1.jpg', 1),
    (10, '/uploads/pets/10-1.jpg', 1),
    (11, '/uploads/pets/11-1.jpg', 1),
    (12, '/uploads/pets/12-1.jpg', 1), (12, '/uploads/pets/12-2.jpg', 2),
    (13, '/uploads/pets/13-1.jpg', 1),
    (14, '/uploads/pets/14-1.jpg', 1), (14, '/uploads/pets/14-2.jpg', 2),
    (15, '/uploads/pets/15-1.jpg', 1),
    (16, '/uploads/pets/16-1.jpg', 1),
    (17, '/uploads/pets/17-1.jpg', 1),
    (18, '/uploads/pets/18-1.jpg', 1),
    (19, '/uploads/pets/19-1.jpg', 1),
    (20, '/uploads/pets/20-1.jpg', 1), (20, '/uploads/pets/20-2.jpg', 2),
    (21, '/uploads/pets/21-1.jpg', 1),
    (22, '/uploads/pets/22-1.jpg', 1),
    (23, '/uploads/pets/23-1.jpg', 1),
    (24, '/uploads/pets/24-1.jpg', 1),
    (25, '/uploads/pets/25-1.jpg', 1);

-- Convivencia por especie (1 = perro, 2 = gato). Sin fila = desconocido (RN-46)
INSERT INTO pet_compatibility_rel (id_pet, id_species, result) VALUES
    ( 1, 1, 'YES'), ( 1, 2, 'NO'),
    ( 2, 1, 'YES'), ( 2, 2, 'YES'),
    ( 3, 1, 'YES'),
    ( 4, 1, 'YES'), ( 4, 2, 'NO'),
    ( 5, 1, 'YES'),
    ( 6, 1, 'NO'),  ( 6, 2, 'NO'),
    ( 7, 1, 'YES'), ( 7, 2, 'YES'),
    (11, 1, 'YES'), (11, 2, 'YES'),
    (13, 2, 'YES'),
    (14, 1, 'YES'), (14, 2, 'YES'),
    (17, 2, 'NO'),
    (19, 2, 'YES'),
    (20, 1, 'YES'), (20, 2, 'YES'),
    (21, 1, 'NO');


-- =====================================================================
--  6. PREFERENCIAS
-- =====================================================================
--  Diego (adopter 8) no tiene fila: nunca ha visto el cuestionario.
--  Pablo (adopter 4) tiene fila sin respuestas: "me da igual" en todo.

INSERT INTO adopter_preference (id, id_adopter, requires_children_compatibility, created_at, updated_at)
OVERRIDING SYSTEM VALUE VALUES
    (1, 1, true,  now() - interval '90 days', now() - interval '30 days'),
    (2, 2, false, now() - interval '60 days', now() - interval '60 days'),
    (3, 3, true,  now() - interval '45 days', now() - interval '45 days'),
    (4, 4, false, now() - interval '40 days', now() - interval '40 days'),
    (5, 5, false, now() - interval '30 days', now() - interval '30 days'),
    (6, 6, false, now() - interval '80 days', now() - interval '80 days'),
    (7, 7, false, now() - interval '70 days', now() - interval '70 days');

INSERT INTO preference_species_rel (id_preference, id_species) VALUES
    (1, 1), (2, 1), (2, 2), (3, 1), (5, 2), (6, 1), (7, 2);

INSERT INTO preference_breed_rel (id_preference, id_breed) VALUES
    (3, 6), (3, 8);                         -- Marta: podencos y galgos

INSERT INTO preference_compatibility_rel (id_preference, id_species) VALUES
    (1, 2);                                 -- Lucía tiene una gata

INSERT INTO preference_size (id_preference, size) VALUES
    (1, 'MEDIUM'), (1, 'LARGE'), (3, 'MEDIUM'), (6, 'LARGE');

INSERT INTO preference_sex (id_preference, sex) VALUES
    (5, 'FEMALE');

INSERT INTO preference_age_range (id_preference, age_range) VALUES
    (2, 'YOUNG'), (2, 'ADULT'), (7, 'ADULT'), (7, 'SENIOR');

INSERT INTO preference_activity_level (id_preference, activity_level) VALUES
    (1, 'MEDIUM'), (1, 'HIGH'), (7, 'LOW');


-- Favoritos y descartes. Un descarte caduca 30 días después de updated_at (RN-75)
INSERT INTO pet_rating_rel (id_adopter, id_pet, rating, created_at, updated_at) VALUES
    (1,  7, 'FAVORITE',  now() - interval '10 days', now() - interval '10 days'),
    (1,  6, 'DISCARDED', now() - interval '5 days',  now() - interval '5 days'),
    (1,  9, 'DISCARDED', now() - interval '40 days', now() - interval '40 days'),   -- caducado: vuelve a aparecer
    (2, 16, 'FAVORITE',  now() - interval '8 days',  now() - interval '8 days'),
    (2, 13, 'FAVORITE',  now() - interval '3 days',  now() - interval '3 days'),
    (2, 10, 'DISCARDED', now() - interval '2 days',  now() - interval '2 days'),
    (3,  3, 'FAVORITE',  now() - interval '12 days', now() - interval '12 days'),
    (3,  4, 'FAVORITE',  now() - interval '12 days', now() - interval '12 days'),
    (4,  3, 'FAVORITE',  now() - interval '9 days',  now() - interval '9 days'),
    (4,  9, 'FAVORITE',  now() - interval '4 days',  now() - interval '4 days'),
    (7, 14, 'FAVORITE',  now() - interval '6 days',  now() - interval '6 days'),
    (7, 19, 'DISCARDED', now() - interval '1 day',   now() - interval '1 day');


-- =====================================================================
--  7. TURNOS DE VISITA
-- =====================================================================

INSERT INTO visit_slot (id, id_shelter, slot_date, start_time, end_time, capacity, created_at, updated_at, created_by, updated_by)
OVERRIDING SYSTEM VALUE VALUES
    -- Protectora Huellas (pasados y futuros)
    ( 1, 1, current_date - 30, '10:00', '11:00', 3, now() - interval '35 days', now() - interval '35 days', 2, 2),
    ( 2, 1, current_date - 10, '10:00', '11:00', 3, now() - interval '15 days', now() - interval '15 days', 2, 2),
    ( 3, 1, current_date -  9, '17:00', '18:00', 3, now() - interval '15 days', now() - interval '15 days', 2, 2),
    ( 4, 1, current_date -  6, '10:00', '11:00', 3, now() - interval '12 days', now() - interval '12 days', 2, 2),
    ( 5, 1, current_date -  7, '17:00', '18:00', 3, now() - interval '12 days', now() - interval '12 days', 2, 2),
    ( 6, 1, current_date -  4, '10:00', '11:00', 3, now() - interval '12 days', now() - interval '12 days', 2, 2),
    ( 7, 1, current_date +  3, '10:00', '11:00', 4, now() - interval '8 days',  now() - interval '8 days',  2, 2),
    ( 8, 1, current_date +  5, '17:00', '18:00', 4, now() - interval '8 days',  now() - interval '8 days',  2, 2),
    ( 9, 1, current_date +  6, '10:00', '11:00', 2, now() - interval '8 days',  now() - interval '8 days',  2, 2),
    (10, 1, current_date + 10, '10:00', '12:00', 5, now() - interval '1 day',   now() - interval '1 day',   2, 2),
    -- Bigotes Libres
    (11, 2, current_date - 40, '11:00', '12:00', 2, now() - interval '45 days', now() - interval '45 days', 3, 3),
    (12, 2, current_date -  3, '11:00', '12:00', 2, now() - interval '10 days', now() - interval '10 days', 3, 3),
    (13, 2, current_date +  3, '11:00', '12:00', 3, now() - interval '7 days',  now() - interval '7 days',  3, 3),
    -- Turno modificado ayer: su visita quedó anulada (TURNO_CANCELADO)
    (14, 2, current_date +  4, '18:00', '19:00', 2, now() - interval '7 days',  now() - interval '1 day',   3, 3),
    (15, 2, current_date +  5, '11:00', '12:00', 3, now() - interval '1 day',   now() - interval '1 day',   3, 3),
    -- Patas Nuevas (pendiente de validación: puede crear turnos, RN-22)
    (16, 3, current_date +  7, '10:00', '11:00', 2, now() - interval '3 days',  now() - interval '3 days',  4, 4);


-- =====================================================================
--  8. VISITAS
-- =====================================================================
--  Adoptante → usuario: 1→5 · 2→6 · 3→7 · 4→8 · 5→9 · 6→10 · 7→11

INSERT INTO visit (id, id_adopter, id_pet, id_visit_slot, status, responded_at, rejection_reason,
                   cancelled_at, cancelled_by, void_reason, attendance_recorded_at, attendance_automatic,
                   corrected_by_admin, corrected_at, id_replaced_visit, created_at, updated_at, created_by, updated_by)
OVERRIDING SYSTEM VALUE VALUES
    -- Lucía visitó a Toby y lo adoptó
    ( 1, 1,  1,  1, 'COMPLETED', now() - interval '33 days', NULL, NULL, NULL, NULL,
        now() - interval '28 days', true,  false, NULL, NULL, now() - interval '34 days', now() - interval '28 days', 5, NULL),
    -- Javier y Marta visitaron a Luna: Javier fue el elegido
    ( 2, 2,  2,  2, 'COMPLETED', now() - interval '13 days', NULL, NULL, NULL, NULL,
        now() - interval '8 days',  true,  false, NULL, NULL, now() - interval '14 days', now() - interval '8 days', 6, NULL),
    ( 3, 3,  2,  3, 'COMPLETED', now() - interval '13 days', NULL, NULL, NULL, NULL,
        now() - interval '7 days',  true,  false, NULL, NULL, now() - interval '13 days', now() - interval '7 days', 7, NULL),
    -- Marta y Pablo visitaron a Rocky: los dos han solicitado su adopción
    ( 4, 3,  3,  5, 'COMPLETED', now() - interval '11 days', NULL, NULL, NULL, NULL,
        now() - interval '5 days',  true,  false, NULL, NULL, now() - interval '11 days', now() - interval '5 days', 7, NULL),
    ( 5, 4,  3,  6, 'COMPLETED', now() - interval '8 days',  NULL, NULL, NULL, NULL,
        now() - interval '2 days',  true,  false, NULL, NULL, now() - interval '8 days',  now() - interval '2 days', 8, NULL),
    -- Elena no se presentó a ver a Nala…
    ( 6, 5,  4,  4, 'NO_SHOW',   now() - interval '10 days', NULL, NULL, NULL, NULL,
        (current_date - 6) + time '13:00', false, false, NULL, NULL, now() - interval '10 days', now() - interval '6 days', 9, 2),
    -- …y su otra visita en esa protectora se anuló (RN-103)
    ( 7, 5,  5,  7, 'VOIDED',    now() - interval '7 days',  NULL, NULL, NULL, 'NO_SHOW',
        NULL, false, false, NULL, NULL, now() - interval '7 days', now() - interval '6 days', 9, NULL),
    -- Sergio fue bloqueado: su visita se anuló
    ( 8, 6,  6,  7, 'VOIDED',    now() - interval '6 days',  NULL, NULL, NULL, 'ADOPTER_BLOCKED',
        NULL, false, false, NULL, NULL, now() - interval '6 days', now() - interval '6 days', 10, NULL),
    -- Lucía quiere conocer a Kira (confirmada)
    ( 9, 1,  7,  7, 'CONFIRMED', now() - interval '4 days',  NULL, NULL, NULL, NULL,
        NULL, false, false, NULL, NULL, now() - interval '5 days', now() - interval '4 days', 5, 2),
    -- Pablo pidió ver a Lola hace 3 horas (pendiente)
    (10, 4,  9,  8, 'PENDING',   NULL, NULL, NULL, NULL, NULL,
        NULL, false, false, NULL, NULL, now() - interval '3 hours', now() - interval '3 hours', 8, NULL),
    -- Javier pidió ver a Bruno y la protectora no respondió en 24 h
    (11, 2, 10,  9, 'EXPIRED',   NULL, NULL, NULL, NULL, NULL,
        NULL, false, false, NULL, NULL, now() - interval '2 days', now() - interval '1 day', 6, NULL),
    -- Marta pidió ver a Kira y la protectora lo rechazó
    (12, 3,  7,  8, 'REJECTED',  now() - interval '4 days',
        'Kira ya tiene una visita confirmada esa semana; te proponemos otro turno por el chat.',
        NULL, NULL, NULL, NULL, false, false, NULL, NULL, now() - interval '4 days', now() - interval '4 days', 7, 2),
    -- Pablo canceló su visita a Max con antelación
    (13, 4,  6,  8, 'CANCELLED', now() - interval '3 days',  NULL, now() - interval '1 day', 'ADOPTER', NULL,
        NULL, false, false, NULL, NULL, now() - interval '4 days', now() - interval '1 day', 8, 8),
    -- Thor se dio de baja por tratamiento: la visita de Lucía se anuló
    (14, 1,  8,  8, 'VOIDED',    now() - interval '3 days',  NULL, NULL, NULL, 'MEDICAL_TREATMENT',
        NULL, false, false, NULL, NULL, now() - interval '4 days', now() - interval '2 days', 5, 2),
    -- Carmen visitó a Michi (luego lo adoptó y lo devolvió)
    (15, 7, 13, 11, 'COMPLETED', now() - interval '43 days', NULL, NULL, NULL, NULL,
        now() - interval '38 days', true,  false, NULL, NULL, now() - interval '44 days', now() - interval '38 days', 11, NULL),
    -- Carmen quiere conocer a Garfield (confirmada)
    (16, 7, 14, 13, 'CONFIRMED', now() - interval '5 days',  NULL, NULL, NULL, NULL,
        NULL, false, false, NULL, NULL, now() - interval '5 days', now() - interval '5 days', 11, 3),
    -- La protectora canceló la visita de Elena a Oliver
    (17, 5, 19, 13, 'CANCELLED', now() - interval '5 days',  NULL, now() - interval '1 day', 'SHELTER', NULL,
        NULL, false, false, NULL, NULL, now() - interval '6 days', now() - interval '1 day', 9, 3),
    -- Marta pidió ver a Salem hace 5 horas (pendiente)
    (18, 3, 15, 13, 'PENDING',   NULL, NULL, NULL, NULL, NULL,
        NULL, false, false, NULL, NULL, now() - interval '5 hours', now() - interval '5 hours', 7, NULL),
    -- Cambio de turno: la visita de Javier a Nube se anuló…
    (19, 2, 16, 14, 'VOIDED',    now() - interval '6 days',  NULL, NULL, NULL, 'SLOT_CANCELLED',
        NULL, false, false, NULL, NULL, now() - interval '6 days', now() - interval '1 day', 6, 3),
    -- …y eligió otro turno, que quedó confirmado directamente (RN-111)
    (20, 2, 16, 15, 'CONFIRMED', now() - interval '1 day',   NULL, NULL, NULL, NULL,
        NULL, false, false, NULL, 19, now() - interval '1 day', now() - interval '1 day', 6, NULL),
    -- Pablo fue marcado como no asistido por error; el administrador lo corrigió (RN-108)
    (21, 4, 20, 12, 'COMPLETED', now() - interval '7 days',  NULL, NULL, NULL, NULL,
        (current_date - 3) + time '14:00', false, true, now() - interval '1 day', NULL, now() - interval '7 days', now() - interval '1 day', 8, 1);


-- =====================================================================
--  9. ADOPCIONES
-- =====================================================================

INSERT INTO adoption (id, id_adopter, id_pet, id_visit, status, responded_at, rejection_reason,
                      cancelled_at, cancelled_by, cancellation_reason, void_reason,
                      handed_over_at, returned_at, return_reason, created_at, updated_at, created_by, updated_by)
OVERRIDING SYSTEM VALUE VALUES
    -- Toby se fue a casa con Lucía
    (1, 1,  1,  1, 'COMPLETED',    now() - interval '25 days', NULL, NULL, NULL, NULL, NULL,
        now() - interval '21 days', NULL, NULL, now() - interval '27 days', now() - interval '21 days', 5, 2),
    -- Luna: Javier fue elegido (pendiente de entrega) y Marta no seleccionada
    (2, 2,  2,  2, 'APPROVED',     now() - interval '2 days',  NULL, NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, now() - interval '7 days', now() - interval '2 days', 6, 2),
    (3, 3,  2,  3, 'NOT_SELECTED', now() - interval '2 days',  NULL, NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, now() - interval '6 days', now() - interval '2 days', 7, 2),
    -- Rocky: dos candidatos esperando respuesta
    (4, 3,  3,  4, 'PENDING',      NULL, NULL, NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, now() - interval '4 days', now() - interval '4 days', 7, NULL),
    (5, 4,  3,  5, 'PENDING',      NULL, NULL, NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, now() - interval '1 day',  now() - interval '1 day',  8, NULL),
    -- Michi fue adoptado por Carmen y devuelto
    (6, 7, 13, 15, 'RETURNED',     now() - interval '35 days', NULL, NULL, NULL, NULL, NULL,
        now() - interval '33 days', now() - interval '5 days', 'Alergia de un miembro de la familia.',
        now() - interval '37 days', now() - interval '5 days', 11, 3),
    -- Pablo retiró su solicitud por Canela
    (7, 4, 20, 21, 'CANCELLED',    NULL, NULL, now() - interval '2 hours', 'ADOPTER',
        'Me han ofrecido acoger al perro de un familiar.', NULL,
        NULL, NULL, NULL, now() - interval '12 hours', now() - interval '2 hours', 8, 8);


-- =====================================================================
--  10. CONVERSACIONES Y MENSAJES
-- =====================================================================
--  Una conversación por cada pareja adoptante–protectora con solicitudes (RN-133)

INSERT INTO conversation (id, id_adopter, id_shelter, last_message_at, created_at, updated_at)
OVERRIDING SYSTEM VALUE VALUES
    ( 1, 1, 1, now() - interval '20 days', now() - interval '34 days', now() - interval '20 days'),
    ( 2, 2, 1, now() - interval '2 days',  now() - interval '14 days', now() - interval '2 days'),
    ( 3, 3, 1, now() - interval '5 days',  now() - interval '13 days', now() - interval '5 days'),
    ( 4, 6, 1, now() - interval '6 days',  now() - interval '6 days',  now() - interval '6 days'),
    ( 5, 7, 2, now() - interval '5 days',  now() - interval '44 days', now() - interval '5 days'),
    ( 6, 2, 2, now() - interval '20 hours', now() - interval '6 days', now() - interval '20 hours'),
    ( 7, 4, 1, NULL, now() - interval '8 days',  now() - interval '8 days'),
    ( 8, 5, 1, NULL, now() - interval '10 days', now() - interval '10 days'),
    ( 9, 5, 2, NULL, now() - interval '6 days',  now() - interval '6 days'),
    (10, 3, 2, NULL, now() - interval '5 hours', now() - interval '5 hours'),
    (11, 4, 2, NULL, now() - interval '7 days',  now() - interval '7 days');

INSERT INTO message (id_conversation, sender, body, image_url, read_at, created_at, updated_at) VALUES
    (1, 'ADOPTER', '¡Hola! Me encantó Toby en la visita. ¿Qué necesito para adoptarle?', NULL,
        now() - interval '27 days', now() - interval '27 days', now() - interval '27 days'),
    (1, 'SHELTER', '¡Hola, Lucía! Solo tienes que enviar la solicitud desde su ficha.', NULL,
        now() - interval '27 days', now() - interval '27 days', now() - interval '27 days'),
    (1, 'ADOPTER', '¡Toby ya está en casa y se lleva genial con mi gata!', '/uploads/chat/1-1.jpg',
        now() - interval '19 days', now() - interval '20 days', now() - interval '20 days'),
    (2, 'ADOPTER', '¿Luna se lleva bien con gatos?', NULL,
        now() - interval '13 days', now() - interval '13 days', now() - interval '13 days'),
    (2, 'SHELTER', 'Sí, convive con dos gatos aquí en la protectora.', NULL,
        now() - interval '13 days', now() - interval '13 days', now() - interval '13 days'),
    (2, 'SHELTER', '¡Enhorabuena, Javier! ¿Qué día te viene bien para recoger a Luna?', NULL,
        NULL, now() - interval '2 days', now() - interval '2 days'),
    (3, 'ADOPTER', '¿Rocky podría acompañarme a correr por las mañanas?', NULL,
        now() - interval '5 days', now() - interval '6 days', now() - interval '6 days'),
    (3, 'SHELTER', '¡Le encantaría! Tiene muchísima energía.', NULL,
        NULL, now() - interval '5 days', now() - interval '5 days'),
    (4, 'ADOPTER', '¿Puedo llevar a mi perro a la visita de Max?', NULL,
        now() - interval '6 days', now() - interval '6 days', now() - interval '6 days'),
    (5, 'ADOPTER', 'Michi se está adaptando muy bien.', NULL,
        now() - interval '30 days', now() - interval '30 days', now() - interval '30 days'),
    (5, 'ADOPTER', 'Lo siento muchísimo: tengo que devolver a Michi por una alergia en casa.', NULL,
        now() - interval '6 days', now() - interval '6 days', now() - interval '6 days'),
    (5, 'SHELTER', 'Lo entendemos, Carmen. Gracias por avisarnos con tiempo.', NULL,
        now() - interval '5 days', now() - interval '5 days', now() - interval '5 days'),
    (6, 'SHELTER', 'Hemos cambiado el horario del turno del jueves; por favor, elige otro turno.', NULL,
        now() - interval '1 day', now() - interval '1 day', now() - interval '1 day'),
    (6, 'ADOPTER', 'Hecho, ya he elegido el del viernes. ¡Gracias!', NULL,
        NULL, now() - interval '20 hours', now() - interval '20 hours');


-- =====================================================================
--  11. BLOQUEOS
-- =====================================================================

INSERT INTO adopter_block (id_shelter, id_adopter, reason, details, unblocked_at, created_at, updated_at, created_by, updated_by) VALUES
    -- Activo: Huellas bloqueó a Sergio
    (1, 6, 'INAPPROPRIATE_BEHAVIOR', 'Mensajes ofensivos a una voluntaria.',
        NULL, now() - interval '6 days', now() - interval '6 days', 2, 2),
    -- Historial: Bigotes Libres bloqueó a Elena por error y la desbloqueó
    (2, 5, 'OTHER', 'Bloqueo por error.',
        now() - interval '19 days', now() - interval '20 days', now() - interval '19 days', 3, 3);


-- =====================================================================
--  12. INCIDENCIAS
-- =====================================================================

INSERT INTO incident (id, id_adopter, id_shelter, opened_by, id_visit, id_adoption, reason, details,
                      status, resolved_at, resolution, created_at, updated_at, created_by, updated_by)
OVERRIDING SYSTEM VALUE VALUES
    -- Resuelta: origen de la corrección de la visita 21
    (1, 4, 2, 'ADOPTER', 21, NULL, 'INCORRECT_ATTENDANCE',
        'Me marcaron como no asistido, pero estuve allí; tengo fotos con Canela.',
        'RESOLVED', now() - interval '1 day',
        'Confirmado con la protectora: la visita se realizó. Asistencia corregida.',
        now() - interval '2 days', now() - interval '1 day', 8, 1),
    -- Abierta: Sergio cree que su bloqueo es injusto
    (2, 6, 1, 'ADOPTER', NULL, NULL, 'UNFAIR_BLOCK',
        'Creo que me han bloqueado sin motivo.',
        'OPEN', NULL, NULL, now() - interval '5 days', now() - interval '5 days', 10, NULL),
    -- En revisión: abierta por una protectora sobre un adoptante
    (3, 5, 2, 'SHELTER', 17, NULL, 'INAPPROPRIATE_BEHAVIOR',
        'La adoptante respondió con insultos por chat cuando cancelamos su visita.',
        'IN_REVIEW', NULL, NULL, now() - interval '1 day', now() - interval '12 hours', 3, 1);


-- =====================================================================
--  13. NOTIFICACIONES
-- =====================================================================

INSERT INTO notification (id_user, type, body, read_at, id_visit, id_adoption, id_incident, created_at, updated_at) VALUES
    -- Lucía
    ( 5, 'ADOPTION_APPROVED', '¡Enhorabuena! Has sido elegida para adoptar a Toby.',
        now() - interval '25 days', NULL, 1, NULL, now() - interval '25 days', now() - interval '25 days'),
    ( 5, 'VISIT_CONFIRMED', 'Tu visita para conocer a Kira está confirmada.',
        now() - interval '4 days', 9, NULL, NULL, now() - interval '4 days', now() - interval '4 days'),
    ( 5, 'VISIT_VOIDED', 'Thor necesita un tratamiento veterinario y no está disponible por ahora. Te avisaremos si vuelve a estarlo.',
        NULL, 14, NULL, NULL, now() - interval '2 days', now() - interval '2 days'),
    -- Javier
    ( 6, 'ADOPTION_APPROVED', '¡Enhorabuena! Has sido elegido para adoptar a Luna.',
        NULL, NULL, 2, NULL, now() - interval '2 days', now() - interval '2 days'),
    ( 6, 'VISIT_EXPIRED', 'La protectora no respondió a tiempo a tu solicitud para conocer a Bruno.',
        NULL, 11, NULL, NULL, now() - interval '1 day', now() - interval '1 day'),
    ( 6, 'VISIT_VOIDED', 'La protectora ha cambiado el turno de tu visita a Nube. Elige otro turno.',
        now() - interval '1 day', 19, NULL, NULL, now() - interval '1 day', now() - interval '1 day'),
    ( 6, 'VISIT_CONFIRMED', 'Tu visita para conocer a Nube está confirmada.',
        NULL, 20, NULL, NULL, now() - interval '1 day', now() - interval '1 day'),
    -- Marta
    ( 7, 'VISIT_REJECTED', 'La protectora no ha podido confirmar tu visita para conocer a Kira.',
        now() - interval '4 days', 12, NULL, NULL, now() - interval '4 days', now() - interval '4 days'),
    ( 7, 'ADOPTION_NOT_SELECTED', 'Luna ya ha encontrado un hogar. ¡Gracias por tu interés!',
        NULL, NULL, 3, NULL, now() - interval '2 days', now() - interval '2 days'),
    -- Pablo
    ( 8, 'INCIDENT_RESOLVED', 'Tu incidencia sobre la visita a Canela se ha resuelto.',
        NULL, NULL, NULL, 1, now() - interval '1 day', now() - interval '1 day'),
    -- Elena
    ( 9, 'VISIT_VOIDED', 'Tu visita para conocer a Coco se ha anulado.',
        now() - interval '6 days', 7, NULL, NULL, now() - interval '6 days', now() - interval '6 days'),
    ( 9, 'VISIT_CANCELLED', 'La protectora ha cancelado tu visita para conocer a Oliver.',
        NULL, 17, NULL, NULL, now() - interval '1 day', now() - interval '1 day'),
    -- Sergio
    (10, 'ADOPTER_BLOCKED', 'La protectora Huellas de Valencia ha restringido tu acceso a sus mascotas.',
        now() - interval '6 days', NULL, NULL, NULL, now() - interval '6 days', now() - interval '6 days'),
    (10, 'VISIT_VOIDED', 'Tu visita para conocer a Max se ha anulado.',
        now() - interval '6 days', 8, NULL, NULL, now() - interval '6 days', now() - interval '6 days'),
    -- Carmen
    (11, 'VISIT_CONFIRMED', 'Tu visita para conocer a Garfield está confirmada.',
        now() - interval '5 days', 16, NULL, NULL, now() - interval '5 days', now() - interval '5 days'),
    -- Protectora Huellas: recordatorios
    ( 2, 'ADOPTION_PENDING_REMINDER', 'Tienes solicitudes de adopción de Rocky pendientes de respuesta.',
        NULL, NULL, 4, NULL, now() - interval '1 day', now() - interval '1 day'),
    ( 2, 'HANDOVER_PENDING_REMINDER', 'Recuerda registrar la entrega de Luna cuando se vaya con Javier.',
        NULL, NULL, 2, NULL, now() - interval '1 day', now() - interval '1 day');


-- =====================================================================
--  AJUSTE DE SECUENCIAS
-- =====================================================================

SELECT setval(pg_get_serial_sequence('app_user',           'id'), (SELECT max(id) FROM app_user));
SELECT setval(pg_get_serial_sequence('shelter',            'id'), (SELECT max(id) FROM shelter));
SELECT setval(pg_get_serial_sequence('adopter',            'id'), (SELECT max(id) FROM adopter));
SELECT setval(pg_get_serial_sequence('pet',                'id'), (SELECT max(id) FROM pet));
SELECT setval(pg_get_serial_sequence('adopter_preference', 'id'), (SELECT max(id) FROM adopter_preference));
SELECT setval(pg_get_serial_sequence('visit_slot',         'id'), (SELECT max(id) FROM visit_slot));
SELECT setval(pg_get_serial_sequence('visit',              'id'), (SELECT max(id) FROM visit));
SELECT setval(pg_get_serial_sequence('adoption',           'id'), (SELECT max(id) FROM adoption));
SELECT setval(pg_get_serial_sequence('conversation',       'id'), (SELECT max(id) FROM conversation));
SELECT setval(pg_get_serial_sequence('incident',           'id'), (SELECT max(id) FROM incident));

COMMIT;
