import type { Reloj } from '../../src/server/domain/reloj.js';

// Doble de prueba del Reloj. La interfaz solo tiene ahora(), y esto es lo único
// que imita; además permite fijar el instante para que los tests sean
// reproducibles (no dependen de la hora a la que se ejecutan).
export class RelojFalso implements Reloj {
  private instante: Date;

  constructor(instante: string) {
    this.instante = new Date(instante);
  }

  ahora(): Date {
    // Una copia: si el código modificara la fecha recibida, no cambiaría el reloj
    return new Date(this.instante.getTime());
  }
}
