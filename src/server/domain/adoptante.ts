const EDAD_MINIMA = 18;

// La fecha de "hoy" es la de España, que es donde se usa la plataforma.
// Un Date es un instante (UTC); el día del calendario depende de la zona:
// a las 23:30 UTC del día 22, en España ya es día 23.
const CALENDARIO_ESPANA = new Intl.DateTimeFormat('es-ES', {
  timeZone: 'Europe/Madrid',
  year: 'numeric',
  month: 'numeric',
  day: 'numeric',
});

interface Fecha {
  anio: number;
  mes: number;
  dia: number;
}

// formatToParts devuelve cada trozo por separado ({ type: 'year', value: '2026' }…):
// no depende del orden ni de los separadores con los que se escribe la fecha.
function fechaEnEspana(instante: Date): Fecha {
  const partes = CALENDARIO_ESPANA.formatToParts(instante);
  const parte = (tipo: string): number =>
    Number(partes.find((p) => p.type === tipo)?.value);
  return { anio: parte('year'), mes: parte('month'), dia: parte('day') };
}

// "AAAA-MM-DD" → números. El formato ya lo ha validado Zod en el controlador.
function leerFecha(texto: string): Fecha {
  const [anio = NaN, mes = NaN, dia = NaN] = texto.split('-').map(Number);
  return { anio, mes, dia };
}

// RN-25: el adoptante debe ser mayor de edad.
// Se es mayor de edad desde el día en que se cumplen 18 años. Se compara con
// NÚMEROS (año, luego mes, luego día): comparar textos falla en cuanto un año
// no tiene 4 cifras (9999 + 18 = 10017).
// Una fecha futura da una edad negativa: no es mayor de edad.
// Quien nació un 29 de febrero, en un año no bisiesto cumple el 1 de marzo
// (el 28 de febrero aún le falta un día).
export function esMayorDeEdad(fechaNacimiento: string, ahora: Date): boolean {
  const hoy = fechaEnEspana(ahora);
  const nacimiento = leerFecha(fechaNacimiento);

  const anios = hoy.anio - nacimiento.anio;
  if (anios !== EDAD_MINIMA) {
    return anios > EDAD_MINIMA;
  }
  // Cumple 18 este año: depende de si ya ha llegado su cumpleaños
  if (hoy.mes !== nacimiento.mes) {
    return hoy.mes > nacimiento.mes;
  }
  return hoy.dia >= nacimiento.dia;
}
