// Se ejecuta UNA vez, antes de todos los tests de integración (ver vitest.config.ts).
// Tira y vuelve a crear la BD de los tests, y carga el esquema y los catálogos.
// Así cada `npm test` empieza desde cero, sin restos de la ejecución anterior.
import { existsSync, readFileSync } from 'node:fs';
import { parseEnv } from 'node:util';
import pg from 'pg';
import { cargarConfiguracion } from '../../src/server/config/config.js';

const ARCHIVOS_SQL = ['database/schema.sql', 'database/seed.sql'];

// Devuelve la función de limpieza (teardown), que Vitest ejecuta al terminar
// TODOS los tests.
export default async function prepararBdDeTest(): Promise<() => Promise<void>> {
  if (!existsSync('.env.test')) {
    throw new Error('Falta .env.test: cópialo de .env.example con PGDATABASE=adopciones_test');
  }
  const { bd } = cargarConfiguracion(parseEnv(readFileSync('.env.test', 'utf8')));

  // Protección: este código BORRA la base de datos. Si .env.test apuntara por
  // error a la de desarrollo (adopciones), perderías tus datos.
  if (!bd.nombre.endsWith('_test')) {
    throw new Error(`Por seguridad, la BD de los tests debe terminar en "_test" (es "${bd.nombre}")`);
  }

  // Candado: dos `npm test` a la vez (un hook, otra sesión, una terminal…)
  // se borrarían la BD el uno al otro a mitad de ejecución. Un advisory lock
  // de PostgreSQL es un candado con nombre: la primera ejecución lo coge y la
  // segunda ESPERA en pg_advisory_lock hasta que la primera lo suelta.
  // Vive en una conexión aparte a "postgres" (el DROP … WITH (FORCE) de abajo
  // solo cierra las conexiones a la BD de tests) y dura toda la ejecución.
  // Si el proceso muere, PostgreSQL cierra la conexión y suelta el candado solo.
  const candado = new pg.Client({
    host: bd.host,
    port: bd.puerto,
    database: 'postgres',
    user: bd.usuario,
    password: bd.contrasena,
  });
  await candado.connect();
  await candado.query('SELECT pg_advisory_lock(hashtext($1))', [bd.nombre]);

  // No se puede borrar una BD estando conectado a ella: se usa la BD de
  // mantenimiento "postgres", que existe en cualquier instalación.
  const mantenimiento = new pg.Client({
    host: bd.host,
    port: bd.puerto,
    database: 'postgres',
    user: bd.usuario,
    password: bd.contrasena,
  });
  await mantenimiento.connect();
  try {
    // El nombre de una BD es un identificador, no un valor: no admite $1.
    // escapeIdentifier lo entrecomilla de forma segura ("adopciones_test").
    const nombre = mantenimiento.escapeIdentifier(bd.nombre);
    // WITH (FORCE) cierra las conexiones que hubieran quedado abiertas
    await mantenimiento.query(`DROP DATABASE IF EXISTS ${nombre} WITH (FORCE)`);
    await mantenimiento.query(`CREATE DATABASE ${nombre} TEMPLATE template0 ENCODING 'UTF8'`);
  } finally {
    await mantenimiento.end();
  }

  const cliente = new pg.Client({
    host: bd.host,
    port: bd.puerto,
    database: bd.nombre,
    user: bd.usuario,
    password: bd.contrasena,
  });
  await cliente.connect();
  try {
    // Una consulta sin parámetros puede contener varias sentencias:
    // así se ejecuta un archivo .sql entero, como haría psql -f.
    for (const archivo of ARCHIVOS_SQL) {
      await cliente.query(readFileSync(archivo, 'utf8'));
    }
  } finally {
    await cliente.end();
  }

  // Al acabar todos los tests se suelta el candado: si otra ejecución estaba
  // esperando, empieza ahora (y recreará la BD desde cero).
  return async () => {
    await candado.query('SELECT pg_advisory_unlock(hashtext($1))', [bd.nombre]);
    await candado.end();
  };
}
