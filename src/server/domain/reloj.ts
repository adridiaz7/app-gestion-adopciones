// El dominio nunca pregunta la hora con new Date(): se la pide a un Reloj que
// recibe desde fuera. En producción es el reloj del sistema (ver app.ts); en
// los tests, un Reloj falso que se puede fijar en cualquier instante. Así se
// prueba "cumple 18 años hoy" o "el enlace caduca en 24 h" sin esperar.
export interface Reloj {
  ahora(): Date;
}
