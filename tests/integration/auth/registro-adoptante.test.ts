import { createHash } from 'node:crypto';
import type { Pool } from 'pg';
import request from 'supertest';
import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import { crearApp } from '../../../src/server/app.js';
import type { EnviadorEmail } from '../../../src/server/auth/enviador-email.js';
import { crearPoolDeTest, vaciarUsuariosDePrueba } from '../../helpers/bd.js';
import { RelojFalso } from '../../helpers/reloj.js';

// 23/11/2026 a las 11:00 en España
const AHORA = '2026-11-23T10:00:00Z';
const URL_PUBLICA = 'http://localhost:3000';
const CONTRASENA = 'una contraseña bastante larga';

// Doble de prueba del EnviadorEmail. La interfaz solo tiene
// enviarVerificacionEmail, y esto es lo único que imita: en vez de enviar,
// guarda cada email para que el test pueda leer el enlace.
class EnviadorEmailFalso implements EnviadorEmail {
  readonly enviados: { destinatario: string; enlace: string }[] = [];

  enviarVerificacionEmail(destinatario: string, enlace: string): Promise<void> {
    this.enviados.push({ destinatario, enlace });
    return Promise.resolve();
  }
}

function datosValidos(cambios: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    email: 'lucia@correo.test',
    contrasena: CONTRASENA,
    nombre: 'Lucía',
    apellidos: 'Martínez Pérez',
    telefono: '600 123 456',
    fechaNacimiento: '1995-04-12',
    idProvincia: 46, // Valencia
    localidad: 'Valencia',
    ...cambios,
  };
}

describe('CU-01 · Registrarse como adoptante · POST /api/registro/adoptante', () => {
  let pool: Pool;
  let enviador: EnviadorEmailFalso;

  beforeAll(() => {
    pool = crearPoolDeTest();
  });

  afterAll(async () => {
    await pool.end();
  });

  beforeEach(async () => {
    await vaciarUsuariosDePrueba(pool);
    enviador = new EnviadorEmailFalso();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  function registrar(cuerpo: Record<string, unknown>) {
    const app = crearApp(pool, {
      reloj: new RelojFalso(AHORA),
      enviadorEmail: enviador,
      urlPublica: URL_PUBLICA,
    });
    return request(app).post('/api/registro/adoptante').send(cuerpo);
  }

  async function contarUsuarios(email: string): Promise<number> {
    const resultado = await pool.query<{ total: number }>(
      'SELECT count(*)::int AS total FROM app_user WHERE email = $1',
      [email],
    );
    return resultado.rows[0]?.total ?? 0;
  }

  // ── Caso normal ─────────────────────────────────────────────────────────

  it('responde 201 con { usuario } y solo sus datos públicos', async () => {
    const respuesta = await registrar(datosValidos());

    expect(respuesta.status).toBe(201);
    expect(respuesta.body).toEqual({
      usuario: {
        id: expect.any(Number) as number,
        email: 'lucia@correo.test',
        rol: 'ADOPTANTE',
        emailVerificado: false,
      },
    });
  });

  it('RN-04 / RN-26: crea la cuenta con rol de adoptante y su perfil con provincia y localidad', async () => {
    await registrar(datosValidos());

    const resultado = await pool.query(
      `SELECT u.role, u.email_verified, a.first_name, a.last_name, a.phone,
              to_char(a.birth_date, 'YYYY-MM-DD') AS birth_date, a.id_province, a.city
         FROM app_user u JOIN adopter a ON a.id_user = u.id
        WHERE u.email = $1`,
      ['lucia@correo.test'],
    );

    expect(resultado.rows).toEqual([
      {
        role: 'ADOPTER',
        email_verified: false,
        first_name: 'Lucía',
        last_name: 'Martínez Pérez',
        phone: '600 123 456',
        birth_date: '1995-04-12',
        id_province: 46,
        city: 'Valencia',
      },
    ]);
  });

  it('RN-08: guarda la contraseña con Argon2id y nunca la devuelve', async () => {
    const respuesta = await registrar(datosValidos());

    const resultado = await pool.query<{ password: string }>(
      'SELECT password FROM app_user WHERE email = $1',
      ['lucia@correo.test'],
    );
    const hash = resultado.rows[0]?.password ?? '';
    expect(hash.startsWith('$argon2id$')).toBe(true);
    expect(hash).not.toContain(CONTRASENA);
    expect(respuesta.text).not.toContain(CONTRASENA);
    expect(respuesta.text).not.toContain(hash);
  });

  // ── Email ───────────────────────────────────────────────────────────────

  it('RN-06: guarda el email en minúsculas y sin espacios alrededor', async () => {
    const respuesta = await registrar(datosValidos({ email: '  Lucia@Correo.TEST ' }));

    expect(respuesta.status).toBe(201);
    expect(await contarUsuarios('lucia@correo.test')).toBe(1);
  });

  it('RN-06: un email ya registrado responde 409, aunque cambien las mayúsculas', async () => {
    await registrar(datosValidos());

    const respuesta = await registrar(datosValidos({ email: 'LUCIA@correo.test' }));

    expect(respuesta.status).toBe(409);
    expect(respuesta.body).toEqual({
      error: { codigo: 'EMAIL_YA_REGISTRADO', mensaje: 'Ya existe una cuenta con ese email' },
    });
    const adoptantes = await pool.query<{ total: number }>(
      'SELECT count(*)::int AS total FROM adopter',
    );
    expect(adoptantes.rows[0]?.total).toBe(1);
    // Ni un segundo enlace ni un segundo email
    const enlaces = await pool.query<{ total: number }>(
      'SELECT count(*)::int AS total FROM auth_token',
    );
    expect(enlaces.rows[0]?.total).toBe(1);
    expect(enviador.enviados).toHaveLength(1);
  });

  // ── Mayoría de edad ─────────────────────────────────────────────────────

  it('RN-25: un menor de edad recibe 400, no se crea la cuenta ni se envía email', async () => {
    // Cumple 18 años mañana
    const respuesta = await registrar(datosValidos({ fechaNacimiento: '2008-11-24' }));

    expect(respuesta.status).toBe(400);
    expect(respuesta.body).toEqual({
      error: { codigo: 'MENOR_DE_EDAD', mensaje: 'Debes ser mayor de edad para registrarte' },
    });
    expect(await contarUsuarios('lucia@correo.test')).toBe(0);
    expect(enviador.enviados).toHaveLength(0);
  });

  it('RN-25: una fecha de nacimiento futura no cuela como mayor de edad', async () => {
    const respuesta = await registrar(datosValidos({ fechaNacimiento: '9999-01-01' }));

    expect(respuesta.status).toBe(400);
    expect((respuesta.body as { error: { codigo: string } }).error.codigo).toBe('MENOR_DE_EDAD');
    expect(await contarUsuarios('lucia@correo.test')).toBe(0);
  });

  it('RN-25: quien cumple 18 años hoy puede registrarse', async () => {
    const respuesta = await registrar(datosValidos({ fechaNacimiento: '2008-11-23' }));

    expect(respuesta.status).toBe(201);
  });

  // ── Contraseña ──────────────────────────────────────────────────────────

  it.each([
    { longitud: 11, estado: 400 },
    { longitud: 12, estado: 201 },
    { longitud: 256, estado: 201 },
    { longitud: 257, estado: 400 },
  ])('RN-175: una contraseña de $longitud caracteres responde $estado', async ({ longitud, estado }) => {
    const respuesta = await registrar(datosValidos({ contrasena: 'a'.repeat(longitud) }));

    expect(respuesta.status).toBe(estado);
  });

  // ── Formato de los datos ────────────────────────────────────────────────

  it.each([
    { caso: 'falta el email', cambios: { email: undefined } },
    { caso: 'el email no tiene formato de email', cambios: { email: 'lucia.correo.test' } },
    { caso: 'el nombre está vacío', cambios: { nombre: '   ' } },
    { caso: 'el teléfono tiene letras', cambios: { telefono: '600abc456' } },
    { caso: 'el teléfono es demasiado corto', cambios: { telefono: '600' } },
    { caso: 'la fecha de nacimiento no existe', cambios: { fechaNacimiento: '2000-02-30' } },
    { caso: 'la fecha de nacimiento es anterior a 1900', cambios: { fechaNacimiento: '1899-12-31' } },
    { caso: 'la fecha de nacimiento es del año 0', cambios: { fechaNacimiento: '0000-01-01' } },
    { caso: 'el teléfono es casi todo espacios', cambios: { telefono: '1        2' } },
    { caso: 'la provincia no es un número', cambios: { idProvincia: '46' } },
    { caso: 'la provincia no cabe en un smallint', cambios: { idProvincia: 40000 } },
    { caso: 'falta la localidad', cambios: { localidad: undefined } },
    { caso: 'se intenta elegir el rol', cambios: { rol: 'ADMINISTRADOR' } },
  ])('responde 400 DATOS_NO_VALIDOS si $caso', async ({ cambios }) => {
    const respuesta = await registrar(datosValidos(cambios));

    expect(respuesta.status).toBe(400);
    expect(respuesta.body).toEqual({
      error: { codigo: 'DATOS_NO_VALIDOS', mensaje: 'Datos no válidos' },
    });
  });

  it('un cuerpo que no es JSON válido responde 400 DATOS_NO_VALIDOS', async () => {
    const respuesta = await request(crearApp(pool))
      .post('/api/registro/adoptante')
      .set('Content-Type', 'application/json')
      .send('{"email": ');

    expect(respuesta.status).toBe(400);
    expect(respuesta.body).toEqual({
      error: { codigo: 'DATOS_NO_VALIDOS', mensaje: 'Datos no válidos' },
    });
  });

  it('un cuerpo demasiado grande responde 413 con el formato común, no 500', async () => {
    // express.json() admite hasta 100 KB por defecto
    const respuesta = await registrar(datosValidos({ nombre: 'x'.repeat(200_000) }));

    expect(respuesta.status).toBe(413);
    expect(respuesta.body).toEqual({
      error: { codigo: 'DATOS_NO_VALIDOS', mensaje: 'Datos no válidos' },
    });
  });

  // ── Transacción ─────────────────────────────────────────────────────────

  it('RN-171: si la provincia no existe, responde 400 y no queda una cuenta a medias', async () => {
    // La cuenta (app_user) se inserta antes que el perfil (adopter); es la FK
    // del perfil la que falla. Si no hubiera transacción, la cuenta quedaría.
    const respuesta = await registrar(datosValidos({ idProvincia: 99 }));

    expect(respuesta.status).toBe(400);
    expect(respuesta.body).toEqual({
      error: { codigo: 'PROVINCIA_NO_VALIDA', mensaje: 'La provincia no existe' },
    });
    expect(await contarUsuarios('lucia@correo.test')).toBe(0);
    expect(enviador.enviados).toHaveLength(0);
  });

  // ── Verificación del email ──────────────────────────────────────────────

  it('RN-07 / RN-177: crea un enlace de verificación sin usar que caduca a las 24 horas', async () => {
    await registrar(datosValidos());

    const resultado = await pool.query<{ purpose: string; used_at: Date | null; expires_at: Date }>(
      `SELECT t.purpose, t.used_at, t.expires_at
         FROM auth_token t JOIN app_user u ON u.id = t.id_user
        WHERE u.email = $1`,
      ['lucia@correo.test'],
    );

    expect(resultado.rows).toHaveLength(1);
    const enlace = resultado.rows[0];
    expect(enlace?.purpose).toBe('EMAIL_VERIFICATION');
    expect(enlace?.used_at).toBeNull();
    expect(enlace?.expires_at.toISOString()).toBe('2026-11-24T10:00:00.000Z');
  });

  it('RN-07: envía el enlace al email; en la BD solo se guarda el SHA-256 del token', async () => {
    const respuesta = await registrar(datosValidos());

    expect(enviador.enviados).toHaveLength(1);
    const enviado = enviador.enviados[0];
    expect(enviado?.destinatario).toBe('lucia@correo.test');

    const prefijo = `${URL_PUBLICA}/verificar-email.html#token=`;
    expect(enviado?.enlace.startsWith(prefijo)).toBe(true);
    const token = enviado?.enlace.slice(prefijo.length) ?? '';
    expect(token).not.toBe('');

    const resultado = await pool.query<{ token_hash: string }>('SELECT token_hash FROM auth_token');
    // El SHA-256 se calcula aquí con node:crypto, sin usar el código probado
    const sha256 = createHash('sha256').update(token).digest('hex');
    expect(resultado.rows[0]?.token_hash).toBe(sha256);
    expect(respuesta.text).not.toContain(token);
  });
});
