// RN-177: el enlace de verificación de email caduca a las 24 horas.
const VALIDEZ_ENLACE_MS = 24 * 60 * 60 * 1000;

// Recibe "ahora" desde fuera (del Reloj): el dominio no pregunta la hora.
// new Date(milisegundos) no lee el reloj del sistema: solo construye la fecha.
export function caducidadEnlaceVerificacion(ahora: Date): Date {
  return new Date(ahora.getTime() + VALIDEZ_ENLACE_MS);
}
