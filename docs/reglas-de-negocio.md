# Reglas de negocio — Plataforma de adopción de mascotas (MVP)

> Documento que recoge todas las reglas de negocio acordadas durante el diseño de la base de datos.
> Cada regla tiene un identificador (`RN-XX`) para poder referenciarla desde el código, las pruebas y el resto de la documentación.
> La numeración es secuencial. **A partir del inicio del desarrollo, los identificadores se congelan**: una regla nueva recibirá el siguiente número libre aunque se coloque dentro de su sección, y una regla eliminada no libera su número. Así nunca cambia el número de una regla ya citada en el código o en las pruebas.
>
> **Última actualización:** 18/11/2026

---

## Índice

1. [Alcance del MVP](#1-alcance-del-mvp)
2. [Roles y cuentas de usuario](#2-roles-y-cuentas-de-usuario)
3. [Protectoras](#3-protectoras)
4. [Adoptantes](#4-adoptantes)
5. [Cuestionario de preferencias](#5-cuestionario-de-preferencias)
6. [Mascotas](#6-mascotas)
7. [Búsqueda de mascotas: galería y modo descubrir](#7-búsqueda-de-mascotas-galería-y-modo-descubrir)
8. [Visitas](#8-visitas)
9. [Adopción](#9-adopción)
10. [Chat](#10-chat)
11. [Notificaciones](#11-notificaciones)
12. [Bloqueos](#12-bloqueos)
13. [Administrador](#13-administrador)
14. [Incidencias](#14-incidencias)
15. [Integridad y transacciones](#15-integridad-y-transacciones)
16. [Parámetros configurables](#16-parámetros-configurables)
17. [Fuera del MVP y temas pendientes](#17-fuera-del-mvp-y-temas-pendientes)

---

## 1. Alcance del MVP

| ID | Regla |
|---|---|
| RN-01 | La plataforma conecta protectoras y adoptantes y digitaliza el proceso de adopción de principio a fin. |
| RN-02 | El MVP **incluye**: registro y perfiles, cuestionario de preferencias, búsqueda de mascotas (galería y modo descubrir), favoritos, visitas, adopción, chat, notificaciones, bloqueos, incidencias y funciones del administrador. |
| RN-03 | El MVP **no incluye** donativos, apadrinamiento ni voluntariado. Se añadirán más adelante mediante migraciones si hay tiempo. La base de datos solo modela lo que entra en el MVP. |

---

## 2. Roles y cuentas de usuario

| ID | Regla |
|---|---|
| RN-04 | Existen tres roles: **Adoptante**, **Protectora** y **Administrador**. Cada usuario tiene un único rol. |
| RN-05 | El Administrador no tiene perfil propio: es un usuario con `rol = ADMIN`. |
| RN-06 | El email de acceso es único en toda la plataforma. |
| RN-07 | El email debe verificarse tras el registro. Hasta que se verifica, la cuenta no está activa. |
| RN-08 | La contraseña nunca se guarda en texto plano en un entorno real. *(Su implementación con hash se definirá en la fase de login.)* |
| RN-09 | Cada protectora tiene **una única cuenta** de usuario, compartida por todo su personal (propietario y voluntarios). |
| RN-10 | Un usuario suspendido por el administrador no puede iniciar sesión mientras la suspensión esté activa (ver [RN-154](#13-administrador)). |

### Eliminación de cuenta

| ID | Regla |
|---|---|
| RN-11 | Un usuario puede **eliminar su cuenta** (derecho de supresión del RGPD). Los datos personales se **anonimizan** y el historial se conserva sin ellos. |
| RN-12 | Si se elimina un **adoptante**: sus solicitudes abiertas pasan a `ANULADA` y se anonimizan sus datos personales (nombre, email, teléfono, dirección, datos del hogar…). <br>Si se elimina una **protectora**: sus mascotas pasan a `BAJA`, sus solicitudes abiertas pasan a `ANULADA` con aviso a los adoptantes, y se anonimizan sus datos de contacto. |
| RN-13 | En el chat, los mensajes de una cuenta eliminada se conservan, y el autor aparece como "Usuario eliminado". |

---

## 3. Protectoras

| ID | Regla |
|---|---|
| RN-14 | Al registrarse, una protectora queda en estado de validación `PENDIENTE`. |
| RN-15 | Una protectora **no puede publicar mascotas** hasta que el administrador la valide (`VALIDADA`). |
| RN-16 | El administrador valida la protectora comprobando su **CIF**. No se suben documentos en el MVP. |
| RN-17 | El CIF es único: no puede haber dos protectoras con el mismo CIF. |
| RN-18 | El administrador puede rechazar una solicitud de validación (`RECHAZADA`) indicando el motivo. |
| RN-19 | El administrador puede **revocar** la validación de una protectora ya validada (vuelve a `RECHAZADA`, con motivo). |
| RN-20 | La protectora puede indicar un **email de contacto** público, opcional y distinto del email de acceso. |
| RN-21 | La ubicación de la protectora se guarda con una **provincia** (catálogo) y la localidad en texto. |
| RN-22 | Antes de ser validada, la protectora **puede crear fichas de mascotas y turnos de visita**, pero sus mascotas no son visibles para los adoptantes hasta la validación. |
| RN-23 | Si a una protectora se le **revoca la validación** o se le **suspende la cuenta**, sus mascotas dejan de ser visibles hasta que vuelva a estar validada y activa. Las visitas y adopciones **en curso se mantienen**, para que el adoptante pueda acudir a la protectora y terminar lo pendiente. |
| RN-24 | En el buscador solo aparecen las protectoras **validadas y no suspendidas**. |

---

## 4. Adoptantes

| ID | Regla |
|---|---|
| RN-25 | El adoptante debe ser **mayor de edad**. La fecha de nacimiento es obligatoria y se comprueba al registrarse. |
| RN-26 | La ubicación del adoptante se guarda con una **provincia** (catálogo) y la localidad en texto. |
| RN-27 | Los **datos del hogar** (tipo de vivienda, jardín o terraza, propiedad o alquiler, convivientes, niños, otras mascotas, experiencia previa, horas que pasaría solo el animal) son **opcionales al registrarse** pero **obligatorios para solicitar una adopción**. |
| RN-28 | Las otras mascotas que tenga el adoptante en casa se describen en texto libre. |
| RN-29 | Una protectora **solo puede ver los datos personales y del hogar** de los adoptantes que le han enviado alguna solicitud. |

---

## 5. Cuestionario de preferencias

| ID | Regla |
|---|---|
| RN-30 | La primera vez que se registra, al adoptante se le ofrece rellenar un cuestionario de preferencias. Es **opcional**. |
| RN-31 | Las preferencias se pueden editar en cualquier momento desde el perfil. |
| RN-32 | El cuestionario pregunta por: **especie, raza, tamaño, edad, sexo, nivel de actividad, convivencia con niños y convivencia con otras especies**. |
| RN-33 | Todas las preguntas admiten **varias respuestas** y la opción **"me da igual"**. |
| RN-34 | No es obligatorio responder todas las preguntas. Una pregunta sin responder equivale a "me da igual". |
| RN-35 | "Me da igual" significa que esa característica **no filtra** las mascotas. |
| RN-36 | Si el adoptante indica que necesita una mascota que se lleve bien con niños, solo se muestran mascotas con `convivencia_ninos = SI`. Las de valor `DESCONOCIDO` se excluyen. |
| RN-37 | Si el adoptante indica que necesita una mascota que se lleve bien con una especie (perros o gatos), solo se muestran mascotas con resultado `SI` para esa especie. Si marca varias especies, debe ser `SI` en todas. |
| RN-38 | Al editar las preferencias se **borran todos los descartes** (`DESCARTADA`) del adoptante. Los favoritos (`FAVORITO`) se conservan. |

---

## 6. Mascotas

### 6.1 Datos de la mascota

| ID | Regla |
|---|---|
| RN-39 | En el MVP solo hay dos especies: **perro y gato**. |
| RN-40 | Cada mascota tiene una raza obligatoria. Cada especie tiene en el catálogo una raza **"Mestizo / Desconocida"**. |
| RN-41 | La especie de una mascota se obtiene **a través de su raza** (no se guarda por separado). |
| RN-42 | Las especies y razas se gestionan como catálogo; solo el administrador puede añadirlas o editarlas. |
| RN-43 | Se guarda la **fecha de nacimiento aproximada**. La franja de edad (cachorro, joven, adulto, senior) se **calcula**, no se guarda. |
| RN-44 | Tamaño: `PEQUENO`, `MEDIANO`, `GRANDE`. Sexo: `MACHO`, `HEMBRA`. Nivel de actividad: `BAJO`, `MEDIO`, `ALTO`. |
| RN-45 | Convivencia con niños: `SI`, `NO` o `DESCONOCIDO`. |
| RN-46 | La convivencia con otros animales se registra **por especie**, con resultado `SI` o `NO`. Si no hay registro para una especie, se considera desconocido. |
| RN-47 | Datos de salud: vacunada, desparasitada, esterilizada, con microchip (solo si lo tiene, no el número) y necesidades especiales (texto opcional). |
| RN-48 | La ficha puede mostrar una **tasa de adopción** informativa (opcional). No es un pago dentro de la app. |
| RN-49 | Se guarda la **fecha de alta** de la mascota para saber cuánto tiempo lleva esperando un hogar. |

### 6.2 Fotos

| ID | Regla |
|---|---|
| RN-50 | Una mascota puede tener **como máximo 6 fotos**. |
| RN-51 | Las fotos tienen un orden. La foto con `orden = 1` es la **principal** (la que aparece en la galería y el modo descubrir). |
| RN-52 | Las imágenes no se guardan en la base de datos, solo su ruta o URL. |

### 6.3 Estados de la mascota

Estados: `DISPONIBLE`, `RESERVADA`, `ADOPTADA`, `BAJA`.

```
              alta
                │
                ▼
     ┌──────► DISPONIBLE ◄──────────────┐
     │          │      ▲                │
     │ reactivar│      │ cancelación    │ devolución
     │          ▼      │                │
     └────── BAJA    RESERVADA ──► ADOPTADA
          (manual)   (adopción     (entrega
                      aprobada)     completada)
```

| ID | Regla |
|---|---|
| RN-53 | Una mascota nueva se da de alta en estado `DISPONIBLE`. |
| RN-54 | `DISPONIBLE → RESERVADA`: automático, al aprobarse una solicitud de adopción. |
| RN-55 | `RESERVADA → DISPONIBLE`: automático, al cancelarse la adopción aprobada. |
| RN-56 | `RESERVADA → ADOPTADA`: automático, al registrarse la entrega de la mascota. |
| RN-57 | `ADOPTADA → DISPONIBLE`: automático, al registrarse una devolución. |
| RN-58 | Solo las mascotas `DISPONIBLE` son visibles en las búsquedas y admiten solicitudes de visita. |
| RN-59 | Las mascotas **nunca se borran físicamente** de la base de datos (borrado lógico). |

### 6.4 Baja de una mascota

| ID | Regla |
|---|---|
| RN-60 | La protectora puede dar de baja una mascota de forma manual. La baja la **oculta** de los adoptantes, pero la mascota sigue en la base de datos. |
| RN-61 | Solo se puede dar de baja una mascota en estado `DISPONIBLE`. Si está `RESERVADA`, primero hay que cancelar la adopción aprobada. |
| RN-62 | La baja requiere un motivo: `FALLECIMIENTO`, `TRASLADO`, `TRATAMIENTO`, `ACOGIDA`, `ERROR`, `OTRO` o `RETIRADA_POR_ADMIN` (este último solo lo usa el administrador). |
| RN-63 | La baja es **reversible**: la protectora puede reactivar la mascota (vuelve a `DISPONIBLE`). |
| RN-64 | Una mascota dada de baja con motivo `RETIRADA_POR_ADMIN` **no puede ser reactivada** por la protectora. |
| RN-65 | Al dar de baja una mascota, sus visitas `PENDIENTE` y `CONFIRMADA` y sus adopciones `PENDIENTE` pasan a `ANULADA`, guardando el motivo de anulación, y se notifica a los adoptantes afectados. |
| RN-66 | El mensaje al adoptante se genera con una **plantilla según el motivo** de la baja. La protectora no añade texto libre. |
| RN-67 | Al reactivar una mascota, se notifica a los adoptantes cuyas solicitudes se anularon por esa baja (`MASCOTA_DISPONIBLE_DE_NUEVO`). |

---

## 7. Búsqueda de mascotas: galería y modo descubrir

| ID | Regla |
|---|---|
| RN-68 | El adoptante puede buscar mascotas de dos formas: **galería** y **modo descubrir** (en la interfaz se desliza la tarjeta a un lado u otro, tipo *swipe*). |
| RN-69 | El adoptante puede buscar protectoras, por ejemplo por provincia. |
| RN-70 | En el modo descubrir aparece una mascota si: está `DISPONIBLE`, es compatible con las preferencias del adoptante, su protectora **no** ha bloqueado al adoptante y el adoptante **no** la ha valorado ya (o su descarte ha caducado). |
| RN-71 | Una mascota es compatible si, para cada pregunta del cuestionario, el adoptante no tiene preferencia ("me da igual") o el valor de la mascota está entre los que marcó. |
| RN-72 | En el modo descubrir, el adoptante puede **añadir la mascota a favoritos** (`FAVORITO`) o **descartarla** y pasar a la siguiente (`DESCARTADA`). |
| RN-73 | El botón de favorito de la galería guarda la misma valoración (`FAVORITO`). Los favoritos son los mismos vengan del modo descubrir o de la galería. |
| RN-74 | Un adoptante tiene como máximo **una valoración** por mascota (favorito o descartada, no las dos). |
| RN-75 | Un **descarte** caduca a los **30 días**: después, la mascota puede volver a aparecer en el modo descubrir. |
| RN-76 | El adoptante puede quitar favoritos o deshacer descartes. No se guarda historial de valoraciones. |
| RN-77 | Las mascotas de una protectora que ha bloqueado al adoptante **no son visibles** para él (ver [Bloqueos](#12-bloqueos)). |

---

## 8. Visitas

### 8.1 Calendario y turnos de visita

| ID | Regla |
|---|---|
| RN-78 | La protectora publica un calendario de **turnos de visita** concretos (fecha, hora de inicio, hora de fin y capacidad). |
| RN-79 | Un turno admite **varias visitas a la vez** (para distintas mascotas), hasta la capacidad que fija la protectora. |
| RN-80 | Cada visita es **de un adoptante, para una mascota concreta, en un turno**. |
| RN-81 | Una mascota solo puede tener **una visita activa por turno**. |
| RN-82 | Las visitas `PENDIENTE` y `CONFIRMADA` ocupan plaza en el turno. |
| RN-83 | El turno y la mascota deben pertenecer a la misma protectora. |
| RN-84 | Un turno no puede crearse en una fecha pasada, su hora de fin debe ser posterior a la de inicio y su capacidad debe ser como mínimo 1. |
| RN-85 | Solo se pueden **eliminar turnos futuros**. Los turnos que ya han pasado se conservan como historial de las visitas. |

### 8.2 Solicitud de visita

| ID | Regla |
|---|---|
| RN-86 | Solo se pueden solicitar visitas a mascotas en estado `DISPONIBLE`. |
| RN-87 | La visita debe solicitarse con al menos **48 horas** de antelación. No se admiten visitas para el mismo día. |
| RN-88 | Un adoptante bloqueado por la protectora no puede solicitar visitas a sus mascotas. |
| RN-89 | Un adoptante con una visita `NO_ASISTIDA` en una protectora no puede solicitar más visitas en esa protectora (ver RN-102). |
| RN-90 | **Cupo:** un adoptante puede tener como máximo **3 visitas** (`CONFIRMADA` o `REALIZADA`) por protectora en una **ventana móvil de 3 meses**. |
| RN-91 | La ventana se cuenta desde la **fecha de la visita** (la de su turno): cada visita deja de contar 3 meses después de realizarse. Así se recuperan las plazas de una en una. |
| RN-92 | Las visitas `PENDIENTE`, `RECHAZADA`, `CANCELADA`, `CADUCADA` y `ANULADA` no cuentan para el cupo. |
| RN-93 | Si el adoptante ha alcanzado el cupo, el sistema no le deja solicitar una cuarta visita. El frontend debe informarle de cuándo tendrá una plaza disponible. |

### 8.3 Respuesta de la protectora

| ID | Regla |
|---|---|
| RN-94 | La protectora tiene **24 horas** para confirmar o rechazar una solicitud de visita. |
| RN-95 | Si no responde en ese plazo, la solicitud pasa automáticamente a `CADUCADA` y la plaza queda libre. |
| RN-96 | Al rechazar, la protectora puede indicar un motivo. |

### 8.4 Cancelación

| ID | Regla |
|---|---|
| RN-97 | El adoptante puede cancelar una visita **solo con 24 horas o más** de antelación. |
| RN-98 | Con menos de 24 horas, la app **no permite cancelar**. Si no acude, la visita se marcará como `NO_ASISTIDA`. |
| RN-99 | No existe la posibilidad de justificar una ausencia. |
| RN-100 | La protectora puede **cancelar una visita confirmada en cualquier momento**, incluso con menos de 24 h de antelación (puede tener emergencias). La visita pasa a `CANCELADA`, se notifica al adoptante y no le cuenta para el cupo. |
| RN-101 | Al cancelar una visita se registra **quién la cancela** (`ADOPTANTE` o `PROTECTORA`). |

### 8.5 Asistencia

| ID | Regla |
|---|---|
| RN-102 | Si el adoptante no se presenta a una visita confirmada (`NO_ASISTIDA`), **no podrá volver a solicitar visitas ni adopciones en esa protectora**, de forma permanente. Las demás protectoras no se ven afectadas. |
| RN-103 | Además, al registrarse una visita `NO_ASISTIDA` el adoptante **pierde el derecho a adoptar cualquier mascota de esa protectora**: <br>• sus otras visitas abiertas y sus adopciones pendientes en esa protectora pasan a `ANULADA` (motivo `NO_ASISTIDA`); <br>• si tenía una adopción `APROBADA` en esa protectora, se cancela (`cancelada_por = SISTEMA`): la mascota vuelve a `DISPONIBLE` y se avisa a los `NO_SELECCIONADA`. |
| RN-104 | La protectora **solo marca las ausencias** (`NO_ASISTIDA`). |
| RN-105 | La protectora solo puede registrar una ausencia **después** de la visita y **antes de que pasen 48 horas**. Pasado ese plazo, la visita ya está `REALIZADA` y solo el administrador puede corregirla. |
| RN-106 | Si la protectora no marca nada, a las **48 horas** de la visita el sistema la pasa automáticamente a `REALIZADA`. Ante la duda, el sistema favorece al adoptante. |
| RN-107 | Se registra si la asistencia la marcó el sistema o la protectora, y cuándo. |
| RN-108 | El administrador puede corregir una visita `NO_ASISTIDA` a `REALIZADA` tras revisar una incidencia. Queda registrado que la corrección la hizo el administrador y cuándo. |

### 8.6 Anulación de visitas

| ID | Regla |
|---|---|
| RN-109 | Una visita pasa a `ANULADA` (con su motivo) cuando: <br>• la mascota queda `RESERVADA` (`MASCOTA_RESERVADA`); <br>• la mascota se da de baja (motivo de la baja); <br>• la protectora bloquea al adoptante (`ADOPTANTE_BLOQUEADO`); <br>• el adoptante tiene una visita `NO_ASISTIDA` en esa protectora (`NO_ASISTIDA`, RN-103); <br>• la protectora modifica o elimina el turno (`TURNO_CANCELADO`, RN-111); <br>• el administrador suspende al adoptante (`ADOPTANTE_SUSPENDIDO`, RN-158). |
| RN-110 | Al anular una visita se notifica al adoptante. |
| RN-111 | La protectora puede **modificar o eliminar un turno que tiene visitas**. Las visitas afectadas pasan a `ANULADA` (`TURNO_CANCELADO`) y se notifica a los adoptantes invitándoles a elegir otro turno. La nueva solicitud **no tiene que cumplir la antelación de 48 h** y **queda confirmada directamente**, porque la protectora ya había confirmado la visita original. |
| RN-112 | La capacidad de un turno **no puede reducirse por debajo de las plazas ya ocupadas**. |

### 8.7 Estados de la visita

```
                  ┌──► RECHAZADA
                  ├──► CANCELADA
PENDIENTE ────────┼──► CADUCADA
                  ├──► ANULADA
                  └──► CONFIRMADA ──┬──► CANCELADA    (adoptante con ≥ 24 h, o protectora)
                                    ├──► ANULADA
                                    ├──► REALIZADA    (automático a las 48 h, o la protectora)
                                    └──► NO_ASISTIDA  (lo marca la protectora)
```

---

## 9. Adopción

### 9.1 Solicitud de adopción

| ID | Regla |
|---|---|
| RN-113 | Para solicitar la adopción de una mascota, el adoptante debe haber **realizado una visita** (`REALIZADA`) a **esa misma mascota**. |
| RN-114 | La solicitud guarda **qué visita** la origina (trazabilidad). |
| RN-115 | Una misma visita puede servir para volver a solicitar la adopción si una solicitud anterior se canceló o se rechazó, siempre que siga dentro de su plazo de validez (RN-116). No hace falta repetir la visita. |
| RN-116 | Una visita realizada sirve para solicitar la adopción durante **1 mes** desde la fecha de la visita. Pasado ese plazo, el adoptante debe hacer **otra visita** (que consume cupo) antes de solicitar la adopción. |
| RN-117 | El adoptante debe tener completos los **datos del hogar** (RN-27). |
| RN-118 | No puede solicitar la adopción un adoptante con una visita `NO_ASISTIDA` en esa protectora ni uno bloqueado por ella. |
| RN-119 | Un adoptante no puede tener **dos solicitudes abiertas** (`PENDIENTE` o `APROBADA`) para la misma mascota. |
| RN-120 | El adoptante puede retirar su solicitud mientras está `PENDIENTE` (`CANCELADA`). |

### 9.2 Selección del adoptante

| ID | Regla |
|---|---|
| RN-121 | **Varios adoptantes** pueden solicitar la adopción de la misma mascota a la vez. La protectora elige. |
| RN-122 | La protectora no tiene plazo para decidir, pero recibe un **recordatorio cada 3 días** mientras haya solicitudes pendientes. |
| RN-123 | La protectora puede rechazar una solicitud indicando el motivo (`RECHAZADA`). |
| RN-124 | Al aprobar una solicitud: la mascota pasa a `RESERVADA`; las demás solicitudes pendientes de esa mascota pasan a `NO_SELECCIONADA`; las visitas abiertas de la mascota pasan a `ANULADA`; y se notifica a todos los afectados. |
| RN-125 | Una mascota solo puede tener **una adopción** `APROBADA` o `COMPLETADA` a la vez. |

### 9.3 Después de la aprobación

| ID | Regla |
|---|---|
| RN-126 | La adopción se completa **cuando la mascota se va de la protectora**. En ese momento la protectora registra la **entrega** (un clic): la adopción pasa a `COMPLETADA` (con fecha de entrega) y la mascota a `ADOPTADA`. |
| RN-127 | Mientras una adopción esté `APROBADA`, la protectora recibe un **recordatorio diario** para registrar la entrega. |
| RN-128 | El plazo máximo para completar una adopción aprobada es de **5 días**. Si se supera, **no se hace ningún cambio automático**: se avisa al **administrador** para que lo investigue. |
| RN-129 | Una adopción `APROBADA` puede cancelarse por **el adoptante**, **la protectora** o **el sistema** (cancelaciones automáticas, por ejemplo por una visita `NO_ASISTIDA` o una suspensión). Se registra quién cancela (`ADOPTANTE`, `PROTECTORA` o `SISTEMA`) y el motivo. |
| RN-130 | Al cancelarse una adopción aprobada, la mascota vuelve a `DISPONIBLE` y se notifica a los candidatos `NO_SELECCIONADA` de que vuelve a estar disponible. Para adoptarla, deben volver a solicitarlo. |
| RN-131 | Una adopción `COMPLETADA` puede pasar a `DEVUELTA` (con fecha y motivo de devolución). La mascota vuelve a `DISPONIBLE`. |
| RN-132 | Las adopciones `PENDIENTE` pasan a `ANULADA` (con su motivo) si la mascota se da de baja, si la protectora bloquea al adoptante, si el adoptante tiene una visita `NO_ASISTIDA` en esa protectora o si el administrador suspende al adoptante. |

### 9.4 Estados de la adopción

```
                 ┌──► RECHAZADA
                 ├──► NO_SELECCIONADA
PENDIENTE ───────┼──► CANCELADA
                 ├──► ANULADA
                 └──► APROBADA ──┬──► CANCELADA     (adoptante, protectora o sistema)
                                 └──► COMPLETADA ──► DEVUELTA
```

---

## 10. Chat

| ID | Regla |
|---|---|
| RN-133 | Hay **una única conversación por pareja** adoptante–protectora, sea cual sea la mascota. |
| RN-134 | El chat solo se abre cuando el adoptante envía su primera **solicitud** (de visita o de adopción) a esa protectora. La protectora **no puede iniciar** conversaciones. |
| RN-135 | Una vez abierto, el chat **sigue abierto** aunque las solicitudes terminen. |
| RN-136 | Mientras haya un bloqueo activo, **ninguna de las dos partes** puede escribir en el chat. |
| RN-137 | El chat es solo para la comunicación entre personas. Los avisos automáticos van por notificaciones. |
| RN-138 | Se registra cuándo se lee cada mensaje. |
| RN-139 | En el chat se pueden enviar **texto e imágenes**. |

---

## 11. Notificaciones

| ID | Regla |
|---|---|
| RN-140 | Las notificaciones son un canal **separado del chat** y aparecen en un lugar distinto del frontend. |
| RN-141 | Las reciben tanto los adoptantes como las protectoras. |
| RN-142 | Una notificación puede ir ligada como mucho a **una** visita o adopción, para que el usuario pueda abrirla. |
| RN-143 | Los textos automáticos se generan con **plantillas** según el tipo y el motivo. |
| RN-144 | Tipos de notificación previstos (no es una lista cerrada): visita confirmada, rechazada, caducada, cancelada por la protectora y anulada (incluido el cambio de turno); adopción aprobada, no seleccionada y cancelada; mascota disponible de nuevo; recordatorio de adopción pendiente; recordatorio de entrega pendiente; adopción sin completar en plazo (al administrador); adoptante bloqueado; incidencia resuelta. |

---

## 12. Bloqueos

| ID | Regla |
|---|---|
| RN-145 | La protectora puede bloquear a un adoptante **a su criterio**. No hay reglas automáticas de bloqueo. |
| RN-146 | La protectora solo puede bloquear a adoptantes que le hayan enviado **alguna solicitud**, porque son los únicos que puede ver. |
| RN-147 | El bloqueo requiere un motivo (`COMPORTAMIENTO_INADECUADO`, `INFORMACION_FALSA`, `INCUMPLIMIENTOS`, `OTRO`) y admite un detalle opcional. El motivo es **interno**: el adoptante no lo ve. |
| RN-148 | Efectos del bloqueo, que se aplican de una vez: <br>• las mascotas de la protectora dejan de ser visibles para el adoptante; <br>• el adoptante no puede solicitar visitas ni adopciones a esa protectora; <br>• ninguna de las dos partes puede escribir en el chat (RN-136); <br>• sus visitas y adopciones pendientes pasan a `ANULADA` (`ADOPTANTE_BLOQUEADO`); <br>• si tenía una adopción `APROBADA`, pasa a `CANCELADA` por la protectora, la mascota vuelve a `DISPONIBLE` y se avisa a los `NO_SELECCIONADA`. |
| RN-149 | El adoptante bloqueado recibe una **notificación** y ve un **aviso permanente** en el perfil de la protectora, con un texto neutro (por ejemplo, "La protectora X ha restringido tu acceso a sus mascotas"). |
| RN-150 | La protectora puede **desbloquear** al adoptante. El bloqueo no se borra: se registra la fecha de desbloqueo (historial). |
| RN-151 | Solo puede haber **un bloqueo activo** por pareja protectora–adoptante. |
| RN-152 | El administrador puede **supervisar** los bloqueos, por ejemplo para detectar adoptantes problemáticos o protectoras que bloquean de forma abusiva. |

---

## 13. Administrador

El administrador es el usuario que **vela porque todo funcione bien y mantiene la plataforma en equilibrio**.

| ID | Regla |
|---|---|
| RN-153 | Valida, rechaza y revoca la validación de las protectoras (RN-14 a RN-19). |
| RN-154 | Puede **suspender** cuentas de adoptantes y protectoras. Una cuenta suspendida no puede iniciar sesión. |
| RN-155 | Las suspensiones requieren un motivo (`COMPORTAMIENTO_INADECUADO`, `INFORMACION_FALSA`, `CONTENIDO_INAPROPIADO`, `FRAUDE`, `INCIDENCIAS_REITERADAS`, `OTRO`) y admiten un detalle. |
| RN-156 | Las suspensiones se guardan con **historial** (fecha de inicio y de fin). Solo puede haber una suspensión activa por usuario. |
| RN-157 | Al suspender a una **protectora**, sus solicitudes en curso se mantienen (RN-23), aunque no pueda iniciar sesión para gestionarlas. Siguen las reglas automáticas: las visitas pendientes caducan (RN-95), las confirmadas pasan a `REALIZADA` a las 48 h (RN-106) y las adopciones aprobadas no completadas en 5 días se notifican al administrador (RN-128). |
| RN-158 | Al suspender a un **adoptante**, sus visitas y adopciones abiertas pasan a `ANULADA` (`ADOPTANTE_SUSPENDIDO`). Si tenía una adopción `APROBADA`, se cancela (`cancelada_por = SISTEMA`): la mascota vuelve a `DISPONIBLE` y se avisa a los `NO_SELECCIONADA`. |
| RN-159 | Gestiona los **catálogos** (especies y razas). |
| RN-160 | Puede consultar **estadísticas globales** (adopciones, tiempos medios, bloqueos…). |
| RN-161 | Puede **consultar cualquier solicitud**, por ejemplo para resolver disputas. |
| RN-162 | Puede **corregir asistencias** (`NO_ASISTIDA → REALIZADA`) tras revisar una incidencia (RN-108). |
| RN-163 | Puede **retirar** la ficha de una mascota con contenido inapropiado (baja con motivo `RETIRADA_POR_ADMIN`, RN-64). Igual que la baja de la protectora, solo se puede aplicar a mascotas `DISPONIBLE`. |
| RN-164 | Gestiona las **incidencias** (ver [Incidencias](#14-incidencias)). |

---

## 14. Incidencias

| ID | Regla |
|---|---|
| RN-165 | Las incidencias funcionan en **los dos sentidos**: un adoptante puede abrir una incidencia sobre una protectora, y una protectora sobre un adoptante. |
| RN-166 | Una incidencia puede ir ligada, de forma opcional, a **una** visita o adopción. |
| RN-167 | Motivos: `ASISTENCIA_INCORRECTA`, `COMPORTAMIENTO_INADECUADO`, `INFORMACION_FALSA`, `CONTENIDO_INAPROPIADO`, `BLOQUEO_INJUSTO`, `OTRO`. La explicación en texto es **obligatoria**. |
| RN-168 | Estados de la incidencia: `ABIERTO`, `EN_REVISION`, `RESUELTO`, `DESCARTADO`. El administrador registra su resolución y la fecha. |
| RN-169 | Quien abre la incidencia recibe una notificación cuando se resuelve. |
| RN-170 | La otra parte **no** recibe aviso al abrirse la incidencia. Solo se le notifica si la resolución le afecta (por ejemplo, una suspensión o una mascota retirada). |

---

## 15. Integridad y transacciones

| ID | Regla |
|---|---|
| RN-171 | Las operaciones que cambian varias cosas a la vez se ejecutan **en una única transacción**: o se aplican todos los cambios o ninguno. Por ejemplo: aprobar una adopción, cancelarla, registrar una devolución, dar de baja una mascota, bloquear a un adoptante o guardar las preferencias (con el borrado de descartes). |
| RN-172 | Nunca se borran físicamente registros con historial (mascotas, visitas, adopciones, bloqueos, suspensiones, incidencias). Se usan estados o fechas de fin. |
| RN-173 | Criterio común para visitas y adopciones: <br>• **`CANCELADA`**: una de las partes decide echarse atrás. Se registra quién (`cancelada_por`). <br>• **`ANULADA`**: se cierra por una **causa externa** a esa visita o adopción (mascota reservada o dada de baja, bloqueo, suspensión, visita no asistida, turno cancelado). Se registra el motivo (`motivo_anulacion`). |
| RN-174 | Los datos derivados (cupos, plazas libres, franja de edad, especie de la mascota) **se calculan**, no se guardan. La excepción consciente es el estado de la mascota, que se guarda por rendimiento y se mantiene coherente mediante transacciones. |

---

## 16. Parámetros configurables

Estos valores no se escriben fijos en el código: van en la **configuración del backend**, para poder ajustarlos sin reprogramar.

| Parámetro | Valor | Regla |
|---|---|---|
| Antelación mínima para solicitar una visita | 48 h | RN-87 |
| Plazo de la protectora para responder una visita | 24 h | RN-94 |
| Antelación mínima para cancelar una visita | 24 h | RN-97 |
| Tiempo hasta marcar automáticamente una visita como realizada | 48 h | RN-106 |
| Cupo de visitas por protectora | 3 | RN-90 |
| Duración de la ventana móvil del cupo | 3 meses | RN-90 |
| Intervalo de recordatorio de adopción pendiente | 3 días | RN-122 |
| Validez de una visita para solicitar la adopción | 1 mes | RN-116 |
| Intervalo de recordatorio de entrega pendiente | 1 día | RN-127 |
| Plazo máximo para completar una adopción aprobada | 5 días | RN-128 |
| Duración de un descarte | 30 días | RN-75 |
| Número máximo de fotos por mascota | 6 | RN-50 |

---

## 17. Fuera del MVP y temas pendientes

### Funcionalidades para después del MVP (si hay tiempo)
- Donativos.
- Apadrinamiento de mascotas.
- Voluntariado en protectoras.
- Varias cuentas de usuario por protectora.
- Configuración de parámetros desde un panel (tabla `Configuracion`).
- Comunicados generales del administrador.
- Registro de acciones del administrador y gestión de varios administradores.
- Registro de asistencia con código QR.
- Historial de bajas y reactivaciones de mascotas.
- Subida de documentos para validar protectoras.

### Pendiente de definir en fases posteriores
- Modelado de las imágenes del chat (RN-139).
- Bloqueo del turno al reservar la última plaza, para evitar que dos adoptantes la ocupen a la vez.
- Zona horaria: fechas guardadas con zona horaria (`timestamptz`) y hora de España como referencia.
- Hash de contraseñas y gestión de los enlaces de verificación de email (fase de login).
- Decisiones técnicas de PostgreSQL: implementación de los ENUM, tipos de datos, convenciones de nombres y comportamiento al borrar (`ON DELETE`).
