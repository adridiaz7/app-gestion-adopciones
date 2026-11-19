# Plataforma de adopción de mascotas

Aplicación que conecta **protectoras** y **adoptantes** para digitalizar el proceso de adopción de mascotas de principio a fin y reducir su tiempo de gestión.

> Proyecto de aprendizaje: una app construida desde cero con apoyo de IA, documentando el porqué de cada decisión.

## Funcionalidades (MVP)

**Adoptante**
- Cuestionario de preferencias (especie, raza, tamaño, edad, convivencia…).
- Búsqueda de mascotas en galería o en el **modo descubrir** (favorito / descartar), con las mascotas compatibles con sus preferencias.
- Solicitud de visitas en los turnos que publica cada protectora.
- Solicitud de adopción tras haber visitado a la mascota.
- Chat con la protectora y notificaciones del proceso.

**Protectora**
- Alta, edición y baja de mascotas.
- Calendario de turnos de visita.
- Gestión de visitas y adopciones: confirmar, rechazar, comparar candidatos, registrar la entrega o una devolución.
- Bloqueo de adoptantes.

**Administrador**
- Validación de protectoras, suspensión de cuentas y gestión de incidencias.
- Catálogos (especies y razas) y supervisión de la actividad.

Fuera del MVP: donativos, apadrinamiento y voluntariado.

## Estado

- ✅ Reglas de negocio y casos de uso
- ✅ Modelo de datos en PostgreSQL, con datos maestros y datos de prueba
- ⏳ Backend
- ⏳ Frontend

## Estructura

```
.
├── docs/
│   ├── reglas-de-negocio.md   ← reglas numeradas (RN-01 … RN-174)
│   └── casos-de-uso.md        ← casos de uso (CU-01 … CU-48)
└── database/
    ├── schema.sql             ← estructura: tipos, tablas, índices, triggers
    ├── seed.sql               ← datos maestros
    ├── seed_demo.sql          ← datos de prueba
    ├── dump.sql               ← copia completa generada con pg_dump
    └── README.md              ← cómo crear la base de datos, usuarios de prueba y glosario
```

## Puesta en marcha de la base de datos

Requiere PostgreSQL 11 o superior. Desde la raíz del proyecto:

```bash
createdb -U postgres -h localhost adopciones
```

```bash
psql -U postgres -h localhost -d adopciones -v ON_ERROR_STOP=1 -f database/schema.sql -f database/seed.sql -f database/seed_demo.sql
```

Los usuarios de prueba y su contraseña están en [database/README.md](database/README.md).

## Documentación

- [Reglas de negocio](docs/reglas-de-negocio.md)
- [Casos de uso](docs/casos-de-uso.md)
- [Base de datos: puesta en marcha, usuarios de prueba y glosario](database/README.md)
