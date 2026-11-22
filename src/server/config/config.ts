// Único sitio que interpreta las variables de entorno.
// Recibe el entorno como parámetro (en lugar de leer process.env aquí dentro)
// para poder probarlo con cualquier valor.
// Los nombres de las variables (PORT, PGHOST…) se quedan en inglés: son una interfaz
// con el exterior, como las columnas de la BD. Las PG* son además los nombres
// estándar que usan psql y el resto de herramientas de PostgreSQL.

export interface ConfiguracionBd {
  host: string;
  puerto: number;
  nombre: string;
  usuario: string;
  contrasena: string;
}

export interface Configuracion {
  puerto: number;
  bd: ConfiguracionBd;
}

type Entorno = Record<string, string | undefined>;

export function cargarConfiguracion(entorno: Entorno): Configuracion {
  return {
    puerto: leerPuerto(entorno, 'PORT'),
    bd: {
      host: leerTexto(entorno, 'PGHOST'),
      puerto: leerPuerto(entorno, 'PGPORT'),
      nombre: leerTexto(entorno, 'PGDATABASE'),
      usuario: leerTexto(entorno, 'PGUSER'),
      contrasena: leerTexto(entorno, 'PGPASSWORD'),
    },
  };
}

function leerTexto(entorno: Entorno, variable: string): string {
  const valor = entorno[variable];
  if (valor === undefined || valor.trim() === '') {
    throw new Error(`Falta la variable de entorno ${variable} (revisa tu .env)`);
  }
  return valor;
}

function leerPuerto(entorno: Entorno, variable: string): number {
  const valor = leerTexto(entorno, variable);
  const puerto = Number(valor);
  if (!Number.isInteger(puerto) || puerto < 1 || puerto > 65535) {
    throw new Error(`${variable} debe ser un entero entre 1 y 65535 (recibido: "${valor}")`);
  }
  return puerto;
}
