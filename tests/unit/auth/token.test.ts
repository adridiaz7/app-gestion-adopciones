import { describe, expect, it } from 'vitest';
import { generarToken, hashearToken } from '../../../src/server/auth/token.js';

describe('Tokens de un solo uso (CU-01, CU-03, CU-04, CU-05)', () => {
  it('son 32 bytes aleatorios en base64url: 43 caracteres válidos en una URL', () => {
    expect(generarToken()).toMatch(/^[A-Za-z0-9_-]{43}$/);
  });

  it('nunca se repiten', () => {
    const tokens = new Set(Array.from({ length: 100 }, () => generarToken()));

    expect(tokens.size).toBe(100);
  });

  it('el hash es el SHA-256 en hexadecimal (vector de prueba conocido)', () => {
    // SHA-256("abc"), valor publicado en el estándar FIPS 180-2
    expect(hashearToken('abc')).toBe(
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });

  it('el hash de un token tiene 64 caracteres hexadecimales y no contiene el token', () => {
    const token = generarToken();
    const hash = hashearToken(token);

    expect(hash).toMatch(/^[0-9a-f]{64}$/);
    expect(hash).not.toContain(token);
  });
});
