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
  // Dirección con la que se llega a la app desde fuera, para construir los
  // enlaces de los emails (verificar email, restablecer contraseña).
  urlPublica: string;
  bd: ConfiguracionBd;
}

type Entorno = Record<string, string | undefined>;

export function cargarConfiguracion(entorno: Entorno): Configuracion {
  const puerto = leerPuerto(entorno, 'PORT');
  return {
    puerto,
    urlPublica: leerUrlPublica(entorno, puerto),
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

// PUBLIC_URL es opcional: en desarrollo, la app está en http://localhost:<PORT>.
// Se quita la barra final para poder escribir `${urlPublica}/ruta` sin dobles barras.
// Se lee de la configuración, y no de la cabecera Host de la petición, porque
// esa cabecera la elige el cliente: un atacante podría hacer que el enlace del
// email apuntara a su propio dominio.
function leerUrlPublica(entorno: Entorno, puerto: number): string {
  const valor = entorno.PUBLIC_URL?.trim();
  const url = valor === undefined || valor === '' ? `http://localhost:${puerto}` : valor;
  return url.replace(/\/+$/, '');
}

function leerPuerto(entorno: Entorno, variable: string): number {
  const valor = leerTexto(entorno, variable);
  const puerto = Number(valor);
  if (!Number.isInteger(puerto) || puerto < 1 || puerto > 65535) {
    throw new Error(`${variable} debe ser un entero entre 1 y 65535 (recibido: "${valor}")`);
  }
  return puerto;
}
