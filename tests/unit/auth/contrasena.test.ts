import { describe, expect, it } from 'vitest';
import { hashearContrasena, verificarContrasena } from '../../../src/server/auth/contrasena.js';

const CONTRASENA = 'una contraseña bastante larga';

describe('Hash de contraseñas (CU-01, CU-04, CU-05)', () => {
  it('RN-08: el hash es Argon2id con los parámetros acordados (m=19456, t=2, p=1)', async () => {
    const hash = await hashearContrasena(CONTRASENA);

    expect(hash.startsWith('$argon2id$v=19$m=19456,t=2,p=1$')).toBe(true);
  });

  it('RN-08: el hash no contiene la contraseña', async () => {
    const hash = await hashearContrasena(CONTRASENA);

    expect(hash).not.toContain(CONTRASENA);
  });

  it('RN-08: la misma contraseña da hashes distintos (cada uno lleva su propia sal)', async () => {
    const primero = await hashearContrasena(CONTRASENA);
    const segundo = await hashearContrasena(CONTRASENA);

    expect(primero).not.toBe(segundo);
  });

  it('verifica la contraseña correcta y rechaza una distinta', async () => {
    const hash = await hashearContrasena(CONTRASENA);

    expect(await verificarContrasena(hash, CONTRASENA)).toBe(true);
    expect(await verificarContrasena(hash, `${CONTRASENA}!`)).toBe(false);
  });
});
