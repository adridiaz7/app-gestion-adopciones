-- =====================================================================
--  Plataforma de adopción de mascotas — Datos maestros
--  Ejecutar después de schema.sql
--
--  Datos que la aplicación necesita SIEMPRE, también en producción:
--    1. Provincias (código INE)
--    2. Especies (MVP: perro y gato)
--    3. Razas (las más habituales en protectoras, más "Mestizo / Desconocida")
--    4. Usuario administrador
--
--  Los datos de prueba van aparte, en seed_demo.sql.
--
--  Se usan ids explícitos (OVERRIDING SYSTEM VALUE) para que el seed de
--  prueba pueda referenciarlos; al final se ajustan las secuencias.
-- =====================================================================

-- El archivo está en UTF-8 (tildes, ñ). En Windows, psql suele leer en WIN1252.
SET client_encoding = 'UTF8';

BEGIN;

-- =====================================================================
--  1. PROVINCIAS (código INE)
-- =====================================================================

INSERT INTO province (id, name) VALUES
    ( 1, 'Araba/Álava'),
    ( 2, 'Albacete'),
    ( 3, 'Alicante/Alacant'),
    ( 4, 'Almería'),
    ( 5, 'Ávila'),
    ( 6, 'Badajoz'),
    ( 7, 'Illes Balears'),
    ( 8, 'Barcelona'),
    ( 9, 'Burgos'),
    (10, 'Cáceres'),
    (11, 'Cádiz'),
    (12, 'Castellón/Castelló'),
    (13, 'Ciudad Real'),
    (14, 'Córdoba'),
    (15, 'A Coruña'),
    (16, 'Cuenca'),
    (17, 'Girona'),
    (18, 'Granada'),
    (19, 'Guadalajara'),
    (20, 'Gipuzkoa'),
    (21, 'Huelva'),
    (22, 'Huesca'),
    (23, 'Jaén'),
    (24, 'León'),
    (25, 'Lleida'),
    (26, 'La Rioja'),
    (27, 'Lugo'),
    (28, 'Madrid'),
    (29, 'Málaga'),
    (30, 'Murcia'),
    (31, 'Navarra'),
    (32, 'Ourense'),
    (33, 'Asturias'),
    (34, 'Palencia'),
    (35, 'Las Palmas'),
    (36, 'Pontevedra'),
    (37, 'Salamanca'),
    (38, 'Santa Cruz de Tenerife'),
    (39, 'Cantabria'),
    (40, 'Segovia'),
    (41, 'Sevilla'),
    (42, 'Soria'),
    (43, 'Tarragona'),
    (44, 'Teruel'),
    (45, 'Toledo'),
    (46, 'Valencia/València'),
    (47, 'Valladolid'),
    (48, 'Bizkaia'),
    (49, 'Zamora'),
    (50, 'Zaragoza'),
    (51, 'Ceuta'),
    (52, 'Melilla');


-- =====================================================================
--  2. ESPECIES
-- =====================================================================

INSERT INTO species (id, name) OVERRIDING SYSTEM VALUE VALUES
    (1, 'Perro'),
    (2, 'Gato');


-- =====================================================================
--  3. RAZAS
-- =====================================================================
--  Cada especie tiene "Mestizo / Desconocida" (RN-40).
--  Perro: ids 1–22 · Gato: ids 23–33

INSERT INTO breed (id, id_species, name) OVERRIDING SYSTEM VALUE VALUES
    -- Perro
    ( 1, 1, 'Mestizo / Desconocida'),
    ( 2, 1, 'Labrador Retriever'),
    ( 3, 1, 'Golden Retriever'),
    ( 4, 1, 'Pastor Alemán'),
    ( 5, 1, 'Pastor Belga Malinois'),
    ( 6, 1, 'Podenco Andaluz'),
    ( 7, 1, 'Podenco Ibicenco'),
    ( 8, 1, 'Galgo Español'),
    ( 9, 1, 'Bodeguero Andaluz'),
    (10, 1, 'Mastín Español'),
    (11, 1, 'Border Collie'),
    (12, 1, 'Beagle'),
    (13, 1, 'Bóxer'),
    (14, 1, 'American Staffordshire Terrier'),
    (15, 1, 'Pit Bull Terrier'),
    (16, 1, 'Yorkshire Terrier'),
    (17, 1, 'Chihuahua'),
    (18, 1, 'Teckel'),
    (19, 1, 'Caniche'),
    (20, 1, 'Bulldog Francés'),
    (21, 1, 'Husky Siberiano'),
    (22, 1, 'Setter Inglés'),
    -- Gato
    (23, 2, 'Mestizo / Desconocida'),
    (24, 2, 'Común Europeo'),
    (25, 2, 'Siamés'),
    (26, 2, 'Persa'),
    (27, 2, 'Maine Coon'),
    (28, 2, 'Británico de Pelo Corto'),
    (29, 2, 'Bengalí'),
    (30, 2, 'Ragdoll'),
    (31, 2, 'Azul Ruso'),
    (32, 2, 'Angora Turco'),
    (33, 2, 'Sphynx');


-- =====================================================================
--  4. USUARIO ADMINISTRADOR
-- =====================================================================
--  Contraseña de desarrollo: ver database/README.md.
--  Hash bcrypt (coste 10). ¡Cambiarla antes de desplegar en producción!

INSERT INTO app_user (id, email, password, role, email_verified) OVERRIDING SYSTEM VALUE VALUES
    (1, 'admin@adopciones.test',
        '$2a$10$2Dq0w6NRTOID2G1xporNUO2ZG2e3qYOzHmDdzmwk89UymFC5YUJAi',
        'ADMIN', true);


-- =====================================================================
--  AJUSTE DE SECUENCIAS
-- =====================================================================
--  Al insertar ids a mano, la secuencia de cada IDENTITY no avanza: se
--  ajusta al máximo id para que el siguiente INSERT normal no choque.

SELECT setval(pg_get_serial_sequence('species',  'id'), (SELECT max(id) FROM species));
SELECT setval(pg_get_serial_sequence('breed',    'id'), (SELECT max(id) FROM breed));
SELECT setval(pg_get_serial_sequence('app_user', 'id'), (SELECT max(id) FROM app_user));

COMMIT;
