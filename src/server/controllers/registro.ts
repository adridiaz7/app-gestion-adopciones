import type { RequestHandler } from 'express';
import type { Pool } from 'pg';
import { z } from 'zod';
import type { DatosRegistroAdoptante, RespuestaRegistro } from '../../shared/registro.js';
import { hashearContrasena } from '../auth/contrasena.js';
import type { EnviadorEmail } from '../auth/enviador-email.js';
import { generarToken, hashearToken } from '../auth/token.js';
import { conTransaccion } from '../db/transaccion.js';
import { esMayorDeEdad } from '../domain/adoptante.js';
import { DatosNoValidos, MenorDeEdad } from '../domain/errores.js';
import type { Reloj } from '../domain/reloj.js';
import { caducidadEnlaceVerificacion } from '../domain/verificacion-email.js';
import { insertarAdoptante } from '../models/adoptante.js';
import { insertarAuthToken } from '../models/auth-token.js';
import { insertarUsuario } from '../models/usuario.js';

// FORMATO de los datos (Zod). Las reglas de negocio (mayoría de edad, email
// repetido, provincia existente) no van aquí: se comprueban en el dominio o
// en la BD (ver TECH_SPEC, "Validación de la entrada").
// Las longitudes máximas son las de las columnas de schema.sql.
const esquemaRegistroAdoptante = z.strictObject({
  // RN-06: se guarda en minúsculas y sin espacios, igual que lo compara el índice único
  email: z.string().trim().toLowerCase().pipe(z.email().max(254)),
  // RN-175: de 12 a 256 caracteres, sin reglas de composición. No se recorta:
  // los espacios forman parte de la contraseña.
  contrasena: z.string().min(12).max(256),
  nombre: z.string().trim().min(1).max(80),
  apellidos: z.string().trim().min(1).max(120),
  // Dígitos y espacios, con un + inicial opcional; de 9 a 20 caracteres y
  // al menos 9 cifras (si no, "1        2" pasaría)
  telefono: z
    .string()
    .trim()
    .regex(/^\+?[0-9 ]{9,20}$/)
    .max(20)
    .refine((telefono) => telefono.replace(/\D/g, '').length >= 9),
  // AAAA-MM-DD y una fecha que exista (rechaza el 30 de febrero). Desde 1900:
  // evita años absurdos (PostgreSQL no tiene año 0). Las fechas futuras las
  // rechaza la regla de mayoría de edad (RN-25), que es quien conoce "hoy".
  // Comparar como texto es seguro aquí: z.iso.date() garantiza 4 cifras de año.
  fechaNacimiento: z.iso.date().refine((fecha) => fecha >= '1900-01-01'),
  // province.id es smallint: un número mayor no cabe y PostgreSQL daría un 500
  idProvincia: z.number().int().positive().max(32767),
  localidad: z.string().trim().min(1).max(100),
});
// z.strictObject rechaza cualquier campo de más. Por ejemplo, { rol: 'ADMINISTRADOR' }:
// el rol lo decide el endpoint, nunca el cliente.

// El tipo inferido de Zod debe coincidir con el contrato compartido con el
// cliente: si alguien cambia uno sin el otro, typecheck falla aquí.
const comprobarContrato: (datos: z.infer<typeof esquemaRegistroAdoptante>) => DatosRegistroAdoptante =
  (datos) => datos;

// CU-01 · Registrarse como adoptante
export function registrarAdoptante(
  pool: Pool,
  reloj: Reloj,
  enviadorEmail: EnviadorEmail,
  urlPublica: string,
): RequestHandler {
  return async (req, res) => {
    const validacion = esquemaRegistroAdoptante.safeParse(req.body);
    if (!validacion.success) {
      throw new DatosNoValidos();
    }
    const datos = comprobarContrato(validacion.data);
    const ahora = reloj.ahora();

    // RN-25
    if (!esMayorDeEdad(datos.fechaNacimiento, ahora)) {
      throw new MenorDeEdad();
    }

    // El hash se calcula FUERA de la transacción: tarda (es lento a propósito)
    // y no hace falta tener la conexión ocupada mientras tanto.
    const hashContrasena = await hashearContrasena(datos.contrasena); // RN-08
    const token = generarToken();

    // RN-171: cuenta, perfil y enlace se crean juntos o no se crea nada
    const usuario = await conTransaccion(pool, async (cliente) => {
      const nuevo = await insertarUsuario(cliente, {
        email: datos.email,
        hashContrasena,
        rol: 'ADOPTANTE', // RN-04: lo fija el endpoint
      });
      await insertarAdoptante(cliente, nuevo.id, datos);
      await insertarAuthToken(cliente, {
        idUsuario: nuevo.id,
        proposito: 'VERIFICAR_EMAIL',
        hashToken: hashearToken(token),
        caducaEn: caducidadEnlaceVerificacion(ahora), // RN-177
      });
      return nuevo;
    });

    // RN-07: el email se envía DESPUÉS del COMMIT. Si se enviara dentro de la
    // transacción y luego esta fallara, la persona recibiría un enlace a una
    // cuenta que no existe.
    // El token va en el fragmento (#), no en la query (?): el navegador nunca
    // envía el fragmento al servidor, así que no queda en los logs ni en la
    // cabecera Referer. La página lo leerá con JavaScript (CU-03).
    await enviadorEmail.enviarVerificacionEmail(
      usuario.email,
      `${urlPublica}/verificar-email.html#token=${token}`,
    );

    const respuesta: RespuestaRegistro = { usuario };
    res.status(201).json(respuesta);
  };
}
