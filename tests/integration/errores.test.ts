import type { NextFunction, Request, Response } from 'express';
import type { Pool } from 'pg';
import request from 'supertest';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { crearApp } from '../../src/server/app.js';
import { manejarErrores } from '../../src/server/middlewares/errores.js';

// Un pool falso cuya consulta siempre falla: simula la BD caída o un error de SQL
// sin tener que romper la BD de verdad.
// OJO: solo imita `query`, que es lo único que usa hoy GET /api/provincias (la
// "ruta víctima" de estos tests). Si el modelo pasara a usar pool.connect()
// (transacciones), fallaría con un TypeError: seguiría dando 500 y el test
// pasaría, pero por un motivo distinto del que dice probar.
const DETALLE_INTERNO = 'conexión rechazada en 10.0.0.5:5432';
const poolQueFalla = {
  query: () => Promise.reject(new Error(DETALLE_INTERNO)),
} as unknown as Pool;

describe('Errores de la API · formato común (TECH_SPEC, sección Errores)', () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('un error inesperado responde 500 con { error: { codigo, mensaje } }', async () => {
    // El error se registra en la consola del servidor: se silencia en el test
    vi.spyOn(console, 'error').mockImplementation(() => undefined);

    const respuesta = await request(crearApp(poolQueFalla)).get('/api/provincias');

    expect(respuesta.status).toBe(500);
    expect(respuesta.body).toEqual({
      error: {
        codigo: 'ERROR_INTERNO',
        mensaje: 'Ha ocurrido un error inesperado. Inténtalo de nuevo más tarde.',
      },
    });
  });

  it('el detalle interno no llega al cliente, pero sí queda en el registro del servidor', async () => {
    const registro = vi.spyOn(console, 'error').mockImplementation(() => undefined);

    const respuesta = await request(crearApp(poolQueFalla)).get('/api/provincias');

    expect(respuesta.text).not.toContain(DETALLE_INTERNO);
    expect(registro).toHaveBeenCalled();
  });

  it('una ruta de la API que no existe responde 404 con el formato común', async () => {
    const respuesta = await request(crearApp(poolQueFalla)).get('/api/no-existe');

    expect(respuesta.status).toBe(404);
    expect(respuesta.body).toEqual({
      error: {
        codigo: 'RUTA_NO_ENCONTRADA',
        mensaje: 'La ruta solicitada no existe.',
      },
    });
  });

  // Esto no se puede provocar desde fuera con una petición (ninguna ruta envía
  // la respuesta por partes), así que se llama al middleware directamente.
  it('si la respuesta ya había empezado a enviarse, no intenta responder otra vez: se lo pasa a Express', () => {
    vi.spyOn(console, 'error').mockImplementation(() => undefined);
    const error = new Error('fallo a mitad de respuesta');
    const status = vi.fn();
    const res = { headersSent: true, status } as unknown as Response;
    const next = vi.fn();

    manejarErrores(error, {} as Request, res, next as NextFunction);

    expect(status).not.toHaveBeenCalled();
    expect(next).toHaveBeenCalledWith(error);
  });
});
