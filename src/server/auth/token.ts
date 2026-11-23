import { createHash, randomBytes } from 'node:crypto';

// Un token es un secreto: quien lo tiene, puede usar el enlace (o la sesión).
// Por eso se genera con randomBytes, el generador criptográfico de Node.
// Un generador no criptográfico (como el random de Math) o la hora actual son
// predecibles: un atacante podría adivinarlos.
// 32 bytes = 256 bits de azar. En base64url ocupa 43 caracteres y se puede
// poner en una URL sin codificar nada.
export function generarToken(): string {
  return randomBytes(32).toString('base64url');
}

// En la BD se guarda el SHA-256 del token, nunca el token: si alguien leyera
// la tabla, no podría usar los enlaces. Aquí basta un hash rápido (no Argon2),
// porque el token ya es aleatorio y larguísimo: no hay diccionario que probar.
export function hashearToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}
