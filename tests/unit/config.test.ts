import { describe, expect, it } from 'vitest';
import { cargarConfiguracion } from '../../src/server/config/config.js';

// Entorno completo y válido. Cada test cambia o quita solo la variable que le interesa.
const entornoValido = {
  PORT: '4000',
  PGHOST: 'localhost',
  PGPORT: '5432',
  PGDATABASE: 'adopciones',
  PGUSER: 'usuario',
  PGPASSWORD: 'secreto',
};

describe('cargarConfiguracion', () => {
  it('lee el puerto como número', () => {
    expect(cargarConfiguracion(entornoValido).puerto).toBe(4000);
  });

  it('falla si falta PORT', () => {
    expect(() => cargarConfiguracion({ ...entornoValido, PORT: undefined })).toThrow('PORT');
  });

  it('falla si PORT no es un puerto válido', () => {
    expect(() => cargarConfiguracion({ ...entornoValido, PORT: 'abc' })).toThrow('PORT');
    expect(() => cargarConfiguracion({ ...entornoValido, PORT: '70000' })).toThrow('PORT');
  });

  it('sin PUBLIC_URL, la URL pública es http://localhost:<PORT>', () => {
    expect(cargarConfiguracion(entornoValido).urlPublica).toBe('http://localhost:4000');
  });

  it('lee la URL pública de PUBLIC_URL, sin la barra final', () => {
    const configuracion = cargarConfiguracion({
      ...entornoValido,
      PUBLIC_URL: 'https://adopciones.example/',
    });

    expect(configuracion.urlPublica).toBe('https://adopciones.example');
  });

  it('lee la conexión a la base de datos, con el puerto como número', () => {
    expect(cargarConfiguracion(entornoValido).bd).toEqual({
      host: 'localhost',
      puerto: 5432,
      nombre: 'adopciones',
      usuario: 'usuario',
      contrasena: 'secreto',
    });
  });

  it.each(['PGHOST', 'PGPORT', 'PGDATABASE', 'PGUSER', 'PGPASSWORD'])(
    'falla nombrando la variable si falta %s',
    (variable) => {
      expect(() => cargarConfiguracion({ ...entornoValido, [variable]: undefined })).toThrow(
        variable,
      );
    },
  );

  it('falla si PGPORT no es un puerto válido', () => {
    expect(() => cargarConfiguracion({ ...entornoValido, PGPORT: 'abc' })).toThrow('PGPORT');
  });
});
