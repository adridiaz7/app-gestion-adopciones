# Casos de uso — Plataforma de adopción de mascotas (MVP)

> Casos de uso identificados durante el diseño de la base de datos. Las reglas que hay detrás de cada excepción están en [reglas-de-negocio.md](reglas-de-negocio.md).
>
> **Última actualización:** 19/11/2026

## Actores

| Actor | Descripción |
|---|---|
| **Visitante** | Persona sin cuenta o sin sesión iniciada. |
| **Adoptante** | Persona registrada que busca una mascota para adoptar. |
| **Protectora** | Asociación registrada que publica mascotas y gestiona el proceso. Una única cuenta para todo su personal. |
| **Administrador** | Usuario que vela por el buen funcionamiento y el equilibrio de la plataforma. |
| **Sistema** | Procesos automáticos (tareas programadas y acciones encadenadas). |

## Índice

1. [Cuenta y acceso](#1-cuenta-y-acceso)
2. [Preferencias](#2-preferencias)
3. [Búsqueda y favoritos](#3-búsqueda-y-favoritos)
4. [Gestión de mascotas](#4-gestión-de-mascotas)
5. [Turnos de visita](#5-turnos-de-visita)
6. [Seguimiento de solicitudes](#6-seguimiento-de-solicitudes)
7. [Visitas](#7-visitas)
8. [Adopción](#8-adopción)
9. [Chat y notificaciones](#9-chat-y-notificaciones)
10. [Bloqueos](#10-bloqueos)
11. [Incidencias](#11-incidencias)
12. [Administración](#12-administración)
13. [Procesos automáticos](#13-procesos-automáticos)

---

## 1. Cuenta y acceso

**CU-01 · Registrarse como adoptante**

**Actor:** Visitante

**Objetivo:** Crear una cuenta de adoptante con sus datos personales (nombre, apellidos, email, contraseña, teléfono, fecha de nacimiento, provincia y localidad).

**Excepciones:**
- El email ya está registrado en la plataforma.
- La persona es menor de edad.
- Faltan datos obligatorios o tienen un formato incorrecto.

---

**CU-02 · Registrarse como protectora**

**Actor:** Visitante

**Objetivo:** Crear una cuenta de protectora con sus datos (nombre, CIF, dirección, provincia, teléfono…). La cuenta queda pendiente de validación por el administrador.

**Excepciones:**
- El email ya está registrado en la plataforma.
- El CIF ya está registrado por otra protectora.
- Faltan datos obligatorios o tienen un formato incorrecto.

---

**CU-03 · Verificar el email**

**Actor:** Adoptante, Protectora

**Objetivo:** Activar la cuenta pulsando el enlace recibido tras el registro. Si el enlace no llega o caduca, el usuario puede pedir que se le reenvíe.

**Excepciones:**
- El enlace no es válido o ha caducado.
- El email ya estaba verificado.

---

**CU-04 · Iniciar sesión**

**Actor:** Adoptante, Protectora, Administrador

**Objetivo:** Acceder a la plataforma con email y contraseña.

**Excepciones:**
- El email o la contraseña son incorrectos.
- El email no está verificado.
- La cuenta tiene una suspensión activa.
- La cuenta ha sido eliminada.

---

**CU-05 · Recuperar la contraseña**

**Actor:** Adoptante, Protectora, Administrador

**Objetivo:** Establecer una contraseña nueva mediante un enlace enviado al email de la cuenta, cuando el usuario la ha olvidado.

**Excepciones:**
- El email no corresponde a ninguna cuenta activa.
- El enlace no es válido o ha caducado.

---

**CU-06 · Editar el perfil**

**Actor:** Adoptante, Protectora

**Objetivo:**
- **Adoptante:** modificar sus datos personales y completar o actualizar los datos del hogar (tipo de vivienda, jardín o terraza, propiedad o alquiler, convivientes, niños, otras mascotas, experiencia previa, horas que pasaría solo el animal).
- **Protectora:** modificar sus datos públicos (descripción, logo, dirección, teléfono, email de contacto, web, horario).

**Excepciones:**
- Los datos tienen un formato incorrecto.
- Adoptante: la nueva fecha de nacimiento corresponde a un menor de edad.
- Protectora: el CIF nuevo ya está registrado por otra protectora.

---

**CU-07 · Eliminar la cuenta**

**Actor:** Adoptante, Protectora

**Objetivo:** Eliminar su cuenta. Los datos personales se anonimizan y el historial se conserva. Si es un adoptante, sus visitas y adopciones abiertas se anulan. Si es una protectora, sus mascotas pasan a baja y sus visitas y adopciones abiertas se anulan, con aviso a los adoptantes.

**Excepciones:**
- El usuario no confirma la eliminación.

---

## 2. Preferencias

**CU-08 · Rellenar o editar las preferencias**

**Actor:** Adoptante

**Objetivo:** Indicar qué busca en una mascota: especie, raza, tamaño, edad, sexo, nivel de actividad, convivencia con niños y con otras especies. Se ofrece tras el primer registro y se puede editar en cualquier momento desde el perfil. Todas las preguntas admiten varias respuestas y "me da igual". Al editar, se borran sus descartes para que esas mascotas puedan volver a aparecer; sus favoritos se conservan.

**Excepciones:**
- Ninguna: el cuestionario es opcional y todas sus preguntas también.

---

## 3. Búsqueda y favoritos

**CU-09 · Buscar mascotas en la galería**

**Actor:** Adoptante

**Objetivo:** Ver un listado de mascotas disponibles y filtrarlas por sus características.

**Excepciones:**
- No hay mascotas disponibles que cumplan los filtros.
- No se muestran las mascotas de protectoras que han bloqueado al adoptante, ni las de protectoras no validadas o suspendidas.

---

**CU-10 · Descubrir mascotas compatibles**

**Actor:** Adoptante

**Objetivo:** Ver, una a una, mascotas compatibles con sus preferencias en el modo descubrir. Puede añadir cada mascota a favoritos o descartarla y pasar a la siguiente.

**Excepciones:**
- No quedan mascotas compatibles sin valorar (o con el descarte aún vigente).
- No se muestran las mascotas no disponibles, las de protectoras que han bloqueado al adoptante ni las de protectoras no validadas o suspendidas.

---

**CU-11 · Consultar la ficha de una mascota**

**Actor:** Adoptante

**Objetivo:** Ver toda la información de una mascota: fotos, descripción, características, convivencia, salud, tasa de adopción y protectora.

**Excepciones:**
- La mascota no está disponible.
- La protectora ha bloqueado al adoptante.
- La protectora no está validada o está suspendida.

---

**CU-12 · Gestionar los favoritos**

**Actor:** Adoptante

**Objetivo:** Consultar su lista de favoritos, añadir mascotas desde la galería o la ficha, quitar mascotas de la lista y recuperar mascotas descartadas.

**Excepciones:**
- La mascota ya no es visible para el adoptante (no disponible, bloqueo o protectora no validada o suspendida).

---

**CU-13 · Buscar protectoras**

**Actor:** Adoptante

**Objetivo:** Encontrar protectoras, por ejemplo por provincia, y ver su perfil y sus mascotas.

**Excepciones:**
- No hay protectoras que cumplan los filtros.
- No se muestran las protectoras no validadas o suspendidas.
- Si la protectora ha bloqueado al adoptante, el perfil muestra el aviso de acceso restringido y no muestra sus mascotas.

---

## 4. Gestión de mascotas

**CU-14 · Consultar mis mascotas**

**Actor:** Protectora

**Objetivo:** Ver el listado de sus mascotas con su estado (disponible, reservada, adoptada o de baja) y acceder a cada ficha.

**Excepciones:**
- La protectora no tiene mascotas dadas de alta.

---

**CU-15 · Dar de alta una mascota**

**Actor:** Protectora

**Objetivo:** Publicar la ficha de una mascota con sus datos, características, convivencia, salud, tasa de adopción y fotos. Queda en estado disponible.

**Excepciones:**
- Faltan datos obligatorios o tienen un formato incorrecto.
- Se intentan subir más de 6 fotos.
- La protectora no está validada: la ficha se crea, pero no es visible para los adoptantes hasta la validación.

---

**CU-16 · Editar la ficha de una mascota**

**Actor:** Protectora

**Objetivo:** Modificar los datos de una mascota y gestionar sus fotos (añadir, eliminar y ordenar; la primera es la principal).

**Excepciones:**
- Los datos tienen un formato incorrecto.
- La mascota quedaría con más de 6 fotos.

---

**CU-17 · Dar de baja o reactivar una mascota**

**Actor:** Protectora

**Objetivo:**
- **Dar de baja:** ocultar una mascota de los adoptantes indicando el motivo (fallecimiento, traslado, tratamiento, acogida, error u otro). Sus visitas abiertas y adopciones pendientes se anulan y se avisa a los adoptantes con un mensaje según el motivo.
- **Reactivar:** volver a ponerla disponible. Se avisa a los adoptantes cuyas visitas o adopciones se anularon por esa baja.

**Excepciones:**
- Baja: la mascota no está disponible (por ejemplo, está reservada: primero hay que cancelar la adopción aprobada).
- Baja: no se indica el motivo.
- Reactivar: la mascota no está de baja.
- Reactivar: la mascota fue retirada por el administrador.

---

## 5. Turnos de visita

**CU-18 · Consultar el calendario de turnos**

**Actor:** Protectora

**Objetivo:** Ver sus turnos de visita con las plazas ocupadas y libres, y las visitas de cada turno.

**Excepciones:**
- La protectora no tiene turnos creados.

---

**CU-19 · Crear un turno de visita**

**Actor:** Protectora

**Objetivo:** Publicar en su calendario un turno con fecha, hora de inicio, hora de fin y número de plazas.

**Excepciones:**
- La fecha ya ha pasado.
- La hora de fin es anterior a la de inicio.
- La capacidad es menor que 1.

---

**CU-20 · Modificar o eliminar un turno de visita**

**Actor:** Protectora

**Objetivo:** Cambiar la fecha, el horario o la capacidad de un turno, o eliminarlo. Si cambian la fecha o el horario, o si se elimina, sus visitas se anulan y se invita a los adoptantes a elegir otro turno.

**Excepciones:**
- La nueva capacidad es menor que las plazas ya ocupadas.
- Los datos nuevos no son válidos (fecha pasada, hora de fin anterior a la de inicio).
- Eliminar: el turno ya ha pasado (se conserva como historial de las visitas).

---

## 6. Seguimiento de solicitudes

**CU-21 · Consultar mis visitas y adopciones**

**Actor:** Adoptante

**Objetivo:** Ver sus visitas y adopciones con su estado, cuántas visitas le quedan del cupo en cada protectora y cuándo recupera la siguiente plaza.

**Excepciones:**
- El adoptante no tiene visitas ni adopciones.

---

**CU-22 · Consultar la bandeja de solicitudes**

**Actor:** Protectora

**Objetivo:** Ver las solicitudes de visita y de adopción que esperan respuesta, las visitas confirmadas próximas y las adopciones aprobadas pendientes de entrega, con acceso al perfil de cada adoptante.

**Excepciones:**
- No hay solicitudes pendientes.

---

## 7. Visitas

**CU-23 · Solicitar una visita**

**Actor:** Adoptante

**Objetivo:** Reservar plaza en un turno para ver a una mascota concreta. La solicitud queda pendiente de confirmación por la protectora. Si la visita sustituye a otra anulada porque la protectora modificó o eliminó el turno, no necesita 48 horas de antelación y queda confirmada directamente.

**Excepciones:**
- La mascota no está disponible.
- El turno no tiene plazas libres.
- La mascota ya tiene una visita activa en ese turno.
- El turno empieza dentro de menos de 48 horas (salvo si sustituye a una visita anulada por cambio de turno).
- El adoptante ya tiene 3 visitas confirmadas o realizadas en esa protectora en los últimos 3 meses.
- El adoptante tiene una visita no asistida en esa protectora.
- La protectora ha bloqueado al adoptante.

---

**CU-24 · Confirmar o rechazar una visita**

**Actor:** Protectora

**Objetivo:** Responder a una solicitud de visita pendiente. Si la rechaza, puede indicar el motivo. El adoptante recibe una notificación.

**Excepciones:**
- Han pasado más de 24 horas desde la solicitud (la visita ha caducado).
- El adoptante ya ha cancelado la solicitud.

---

**CU-25 · Cancelar una visita**

**Actor:** Adoptante, Protectora

**Objetivo:** Cancelar una visita. Se registra quién la cancela, se notifica a la otra parte y la visita no cuenta para el cupo del adoptante.
- **Adoptante:** puede cancelar una visita pendiente o confirmada con al menos 24 horas de antelación.
- **Protectora:** puede cancelar una visita confirmada en cualquier momento, incluso con menos de 24 horas, por un imprevisto.

**Excepciones:**
- Adoptante: faltan menos de 24 horas para la visita.
- Protectora: la visita no está confirmada.
- La visita ya está cerrada (realizada, no asistida, cancelada, rechazada, caducada o anulada).

---

**CU-26 · Registrar una ausencia**

**Actor:** Protectora

**Objetivo:** Marcar que el adoptante no acudió a una visita confirmada. El adoptante pierde el derecho a visitar y adoptar en esa protectora: sus visitas y adopciones abiertas en ella se anulan y, si tenía una adopción aprobada, se cancela.

**Excepciones:**
- La visita todavía no ha tenido lugar.
- La visita no está confirmada.
- Han pasado más de 48 horas y el sistema ya la marcó como realizada.

---

## 8. Adopción

**CU-27 · Solicitar una adopción**

**Actor:** Adoptante

**Objetivo:** Pedir la adopción de una mascota que ha visitado. La solicitud queda pendiente y puede competir con las de otros adoptantes.

**Excepciones:**
- No tiene una visita realizada a esa mascota.
- La visita se realizó hace más de 1 mes.
- No ha completado los datos del hogar.
- Tiene una visita no asistida en esa protectora.
- La protectora le ha bloqueado.
- Ya tiene una solicitud abierta para esa mascota.
- La mascota no está disponible.

---

**CU-28 · Comparar los candidatos de una mascota**

**Actor:** Protectora

**Objetivo:** Ver todas las solicitudes de adopción pendientes de una mascota, con los datos personales y del hogar de cada candidato, para elegir el mejor hogar.

**Excepciones:**
- La mascota no tiene solicitudes de adopción pendientes.

---

**CU-29 · Aprobar o rechazar una adopción**

**Actor:** Protectora

**Objetivo:**
- **Aprobar:** elegir al adoptante con el que se irá la mascota. La mascota pasa a reservada, el resto de candidatos pasan a no seleccionados, las visitas abiertas de la mascota se anulan y se notifica a todos los afectados.
- **Rechazar:** descartar una solicitud indicando el motivo. El adoptante recibe una notificación.

**Excepciones:**
- La solicitud no está pendiente.
- Aprobar: la mascota ya tiene otra adopción aprobada o completada.

---

**CU-30 · Cancelar una adopción**

**Actor:** Adoptante, Protectora

**Objetivo:**
- **Adoptante:** retirar su solicitud mientras está pendiente, o echarse atrás de una adopción aprobada.
- **Protectora:** echarse atrás de una adopción aprobada.

Se registra quién cancela y el motivo. Si la adopción estaba aprobada, la mascota vuelve a estar disponible y se avisa a los candidatos no seleccionados.

**Excepciones:**
- La adopción ya está cerrada (si ya está completada, corresponde una devolución).
- Protectora: la adopción solo está pendiente (corresponde rechazarla).

---

**CU-31 · Registrar la entrega de la mascota**

**Actor:** Protectora

**Objetivo:** Indicar con un clic que la mascota se ha ido con su adoptante. La adopción pasa a completada y la mascota a adoptada.

**Excepciones:**
- La adopción no está aprobada.

---

**CU-32 · Registrar una devolución**

**Actor:** Protectora

**Objetivo:** Registrar que un adoptante ha devuelto la mascota, con la fecha y el motivo. La mascota vuelve a estar disponible.

**Excepciones:**
- La adopción no está completada.

---

## 9. Chat y notificaciones

**CU-33 · Usar el chat**

**Actor:** Adoptante, Protectora

**Objetivo:** Consultar sus conversaciones, leer los mensajes y escribir texto o enviar imágenes a la otra parte. La conversación se abre con la primera solicitud del adoptante a esa protectora.

**Excepciones:**
- El adoptante no ha enviado ninguna solicitud a esa protectora (la conversación no existe).
- La protectora intenta iniciar una conversación.
- Hay un bloqueo activo entre ambos (no se puede escribir).

---

**CU-34 · Consultar las notificaciones**

**Actor:** Adoptante, Protectora, Administrador

**Objetivo:** Ver sus avisos (visitas, adopciones, recordatorios, bloqueos, incidencias…) y abrir la visita o adopción relacionada. Las notificaciones quedan marcadas como leídas.

**Excepciones:**
- No tiene notificaciones.

---

## 10. Bloqueos

**CU-35 · Bloquear o desbloquear a un adoptante**

**Actor:** Protectora

**Objetivo:**
- **Bloquear:** impedir que un adoptante vea sus mascotas, le envíe solicitudes o le escriba, indicando un motivo interno. Las visitas y adopciones pendientes del adoptante se anulan, una adopción aprobada se cancela, y el adoptante recibe una notificación y ve un aviso en el perfil de la protectora.
- **Desbloquear:** levantar el bloqueo. El bloqueo queda en el historial.

**Excepciones:**
- Bloquear: el adoptante ya está bloqueado.
- Bloquear: el adoptante no ha enviado ninguna solicitud a esa protectora.
- Bloquear: no se indica el motivo.
- Desbloquear: no existe un bloqueo activo para ese adoptante.

---

## 11. Incidencias

**CU-36 · Abrir una incidencia**

**Actor:** Adoptante, Protectora

**Objetivo:** Comunicar un problema al administrador sobre la otra parte, con un motivo y una explicación. Opcionalmente, puede ligarse a una visita o adopción concreta (por ejemplo, para reclamar una ausencia mal registrada).

**Excepciones:**
- Falta la explicación.
- La visita o adopción indicada no pertenece a las partes implicadas.

---

**CU-37 · Gestionar una incidencia**

**Actor:** Administrador

**Objetivo:** Revisar una incidencia, cambiar su estado (en revisión, resuelta o descartada) y registrar la resolución. Quien la abrió recibe una notificación; la otra parte solo si la resolución le afecta.

**Excepciones:**
- La incidencia ya está resuelta o descartada.

---

**CU-38 · Corregir una asistencia**

**Actor:** Administrador

**Objetivo:** Cambiar una visita marcada como no asistida a realizada tras revisar una incidencia. Queda registrado que la corrección la hizo el administrador.

**Excepciones:**
- La visita no está marcada como no asistida.

---

## 12. Administración

**CU-39 · Gestionar la validación de las protectoras**

**Actor:** Administrador

**Objetivo:**
- **Validar o rechazar** una protectora recién registrada, tras comprobar su CIF. Una vez validada, sus mascotas pasan a ser visibles.
- **Revocar** la validación de una protectora que ya no cumple los requisitos. Sus mascotas dejan de ser visibles; sus visitas y adopciones en curso se mantienen.

**Excepciones:**
- Validar o rechazar: la protectora no está pendiente de validación.
- Revocar: la protectora no está validada.
- Se rechaza o se revoca sin indicar el motivo.

---

**CU-40 · Suspender o reactivar una cuenta**

**Actor:** Administrador

**Objetivo:**
- **Suspender** a un adoptante o a una protectora indicando el motivo. El usuario no puede iniciar sesión. Si es un adoptante, sus visitas y adopciones abiertas se anulan y una adopción aprobada se cancela. Si es una protectora, sus mascotas dejan de ser visibles y lo que tiene en curso se mantiene.
- **Reactivar** una cuenta suspendida. La suspensión queda en el historial.

**Excepciones:**
- Suspender: el usuario ya tiene una suspensión activa.
- Suspender: no se indica el motivo.
- Reactivar: el usuario no tiene una suspensión activa.

---

**CU-41 · Retirar una mascota por contenido inapropiado**

**Actor:** Administrador

**Objetivo:** Dar de baja la ficha de una mascota con fotos o textos inadecuados. La protectora no puede reactivarla.

**Excepciones:**
- La mascota no está disponible.

---

**CU-42 · Gestionar los catálogos**

**Actor:** Administrador

**Objetivo:** Añadir o editar especies y razas.

**Excepciones:**
- Ya existe una especie o raza con ese nombre.
- La raza no se asocia a ninguna especie.

---

**CU-43 · Supervisar la actividad**

**Actor:** Administrador

**Objetivo:** Consultar cualquier visita, adopción o bloqueo con su historial, por ejemplo para resolver una disputa o detectar adoptantes problemáticos y protectoras que bloquean de forma abusiva.

**Excepciones:**
- Ninguna.

---

**CU-44 · Consultar estadísticas**

**Actor:** Administrador

**Objetivo:** Ver indicadores globales de la plataforma: adopciones, tiempos medios de gestión, devoluciones, bloqueos, incidencias…

**Excepciones:**
- Ninguna.

---

## 13. Procesos automáticos

**CU-45 · Caducar las visitas sin respuesta**

**Actor:** Sistema

**Objetivo:** Marcar como caducadas las solicitudes de visita que la protectora no ha respondido en 24 horas, liberar su plaza y avisar al adoptante.

**Excepciones:**
- La protectora responde antes de que se cumpla el plazo.

---

**CU-46 · Marcar las visitas como realizadas**

**Actor:** Sistema

**Objetivo:** Marcar como realizadas las visitas confirmadas cuando han pasado 48 horas desde la visita sin que la protectora haya registrado una ausencia.

**Excepciones:**
- La protectora registra una ausencia antes de que se cumpla el plazo.
- La visita se cancela o se anula antes de tener lugar.

---

**CU-47 · Recordar las adopciones pendientes**

**Actor:** Sistema

**Objetivo:** Enviar a la protectora un recordatorio cada 3 días mientras tenga solicitudes de adopción sin responder.

**Excepciones:**
- Ya se envió un recordatorio para esa solicitud en los últimos 3 días.

---

**CU-48 · Recordar las entregas pendientes**

**Actor:** Sistema

**Objetivo:** Enviar a la protectora un recordatorio diario mientras tenga adopciones aprobadas sin entrega registrada y, si pasan 5 días, avisar al administrador.

**Excepciones:**
- La protectora registra la entrega o la adopción se cancela.

---

## Fuera del MVP

No se incluyen casos de uso de donativos, apadrinamiento, voluntariado, comunicados generales, configuración de parámetros desde un panel ni gestión de varios administradores.
