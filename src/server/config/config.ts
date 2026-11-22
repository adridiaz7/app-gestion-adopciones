// Único sitio que interpreta las variables de entorno.
// Recibe el entorno como parámetro (en lugar de leer process.env aquí dentro)
// para poder probarlo con cualquier valor.
// Los nombres de las variables (PORT…) se quedan en inglés: son una interfaz
// con el exterior, como las columnas de la BD.

export interface Configuracion {
  puerto: number;
}

type Entorno = Record<string, string | undefined>;

export function cargarConfiguracion(entorno: Entorno): Configuracion {
  return { puerto: leerPuerto(entorno['PORT']) };
}

function leerPuerto(valor: string | undefined): number {
  if (valor === undefined || valor.trim() === '') {
    throw new Error('Falta la variable de entorno PORT (revisa tu .env)');
  }
  const puerto = Number(valor);
  if (!Number.isInteger(puerto) || puerto < 1 || puerto > 65535) {
    throw new Error(`PORT debe ser un entero entre 1 y 65535 (recibido: "${valor}")`);
  }
  return puerto;
}
