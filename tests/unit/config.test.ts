import { describe, expect, it } from 'vitest';
import { cargarConfiguracion } from '../../src/server/config/config.js';

describe('cargarConfiguracion', () => {
  it('lee el puerto como número', () => {
    expect(cargarConfiguracion({ PORT: '4000' })).toEqual({ puerto: 4000 });
  });

  it('falla si falta PORT', () => {
    expect(() => cargarConfiguracion({})).toThrow('PORT');
  });

  it('falla si PORT no es un puerto válido', () => {
    expect(() => cargarConfiguracion({ PORT: 'abc' })).toThrow('PORT');
    expect(() => cargarConfiguracion({ PORT: '70000' })).toThrow('PORT');
  });
});
