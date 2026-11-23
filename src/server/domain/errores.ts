// Errores de negocio (ver TECH_SPEC, "Errores").
//
// El dominio no conoce HTTP: cada error pertenece a una CATEGORÍA, y solo el
// middleware de errores sabe qué código HTTP corresponde a cada categoría.
// Cada error concreto fija su `codigo` (para el programa) y su `mensaje`
// (para la persona). Crear un error nuevo no obliga a tocar el middleware.

export abstract class ErrorDeNegocio extends Error {
  readonly codigo: string;

  constructor(codigo: string, mensaje: string) {
    super(mensaje);
    this.codigo = codigo;
    // Para que el nombre de la clase concreta salga en los logs y las trazas
    this.name = new.target.name;
  }
}

// ── Categorías ────────────────────────────────────────────────────────────
// Se irán añadiendo NoAutenticado, Prohibido y NoEncontrado cuando hagan falta.

/** Los datos no son aceptables (formato o regla de entrada) → 400 */
export abstract class ErrorDeValidacion extends ErrorDeNegocio {}

/** Choca con el estado actual de los datos → 409 */
export abstract class Conflicto extends ErrorDeNegocio {}

// ── Errores concretos ─────────────────────────────────────────────────────

export class DatosNoValidos extends ErrorDeValidacion {
  constructor() {
    super('DATOS_NO_VALIDOS', 'Datos no válidos');
  }
}

// RN-25
export class MenorDeEdad extends ErrorDeValidacion {
  constructor() {
    super('MENOR_DE_EDAD', 'Debes ser mayor de edad para registrarte');
  }
}

// RN-26: la provincia tiene que existir en el catálogo
export class ProvinciaNoValida extends ErrorDeValidacion {
  constructor() {
    super('PROVINCIA_NO_VALIDA', 'La provincia no existe');
  }
}

// RN-06
export class EmailYaRegistrado extends Conflicto {
  constructor() {
    super('EMAIL_YA_REGISTRADO', 'Ya existe una cuenta con ese email');
  }
}
