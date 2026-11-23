import { describe, expect, it } from 'vitest';
import { esMayorDeEdad } from '../../src/server/domain/adoptante.js';

// 23/11/2026 a las 11:00 en España (10:00 UTC)
const HOY = new Date('2026-11-23T10:00:00Z');

describe('CU-01 · Registrarse como adoptante · mayoría de edad', () => {
  it('RN-25: quien cumple 18 años hoy es mayor de edad', () => {
    expect(esMayorDeEdad('2008-11-23', HOY)).toBe(true);
  });

  it('RN-25: quien los cumple mañana todavía no lo es', () => {
    expect(esMayorDeEdad('2008-11-24', HOY)).toBe(false);
  });

  it('RN-25: una persona adulta lo es', () => {
    expect(esMayorDeEdad('1990-05-10', HOY)).toBe(true);
  });

  it('RN-25: nacido un 29 de febrero, en un año no bisiesto cumple el 1 de marzo', () => {
    expect(esMayorDeEdad('2008-02-29', new Date('2026-02-28T12:00:00Z'))).toBe(false);
    expect(esMayorDeEdad('2008-02-29', new Date('2026-03-01T12:00:00Z'))).toBe(true);
  });

  it('RN-25: una fecha de nacimiento futura no es mayor de edad (ni con un año de 5 cifras al sumar 18)', () => {
    expect(esMayorDeEdad('2030-01-01', HOY)).toBe(false);
    // 9999 + 18 = 10017: comparado como texto, "2026…" sería mayor que "10017…"
    expect(esMayorDeEdad('9999-01-01', HOY)).toBe(false);
  });

  it('RN-25: "hoy" es la fecha en España, no en UTC', () => {
    // 22/11 a las 23:30 UTC = 23/11 a las 00:30 en España: ya es su cumpleaños
    expect(esMayorDeEdad('2008-11-23', new Date('2026-11-22T23:30:00Z'))).toBe(true);
  });
});
