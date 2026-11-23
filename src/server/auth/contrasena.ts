import { hash, verify, type Algorithm, type Options } from '@node-rs/argon2';

// RN-08: las contraseñas se guardan con Argon2id, el algoritmo que recomienda
// OWASP. A diferencia de un hash rápido (SHA-256), Argon2id es lento y gasta
// memoria a propósito: así, quien robara la BD tardaría muchísimo en probar
// contraseñas por fuerza bruta, incluso con tarjetas gráficas.
//
// Parámetros (los mínimos recomendados por OWASP):
//   m = 19456 KiB de memoria (19 MiB) · t = 2 pasadas · p = 1 hilo
//
// `Algorithm` es un "const enum" declarado por la librería: con isolatedModules
// (tsconfig) se puede usar su TIPO, pero no su valor. 2 es Argon2id; el test
// que comprueba el prefijo $argon2id$ del hash garantiza que no nos equivocamos.
const PARAMETROS: Options = {
  algorithm: 2 as Algorithm,
  memoryCost: 19456,
  timeCost: 2,
  parallelism: 1,
};

// El hash incluye una sal aleatoria y los parámetros ($argon2id$v=19$m=…):
// para verificar no hace falta guardar nada más.
export function hashearContrasena(contrasena: string): Promise<string> {
  return hash(contrasena, PARAMETROS);
}

export function verificarContrasena(hashGuardado: string, contrasena: string): Promise<boolean> {
  return verify(hashGuardado, contrasena);
}
