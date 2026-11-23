import type { PoolClient } from 'pg';

// Para qué sirve el enlace. En la BD: ENUM auth_token_purpose (ver glosario).
export type PropositoToken = 'VERIFICAR_EMAIL' | 'RESTABLECER_CONTRASENA';

const PROPOSITO_EN_BD: Record<PropositoToken, string> = {
  VERIFICAR_EMAIL: 'EMAIL_VERIFICATION',
  RESTABLECER_CONTRASENA: 'PASSWORD_RESET',
};

export interface DatosNuevoToken {
  idUsuario: number;
  proposito: PropositoToken;
  hashToken: string; // SHA-256 del token: el token nunca llega a la BD
  caducaEn: Date;
}

export async function insertarAuthToken(
  cliente: PoolClient,
  datos: DatosNuevoToken,
): Promise<void> {
  await cliente.query(
    `INSERT INTO auth_token (id_user, purpose, token_hash, expires_at)
     VALUES ($1, $2, $3, $4)`,
    [datos.idUsuario, PROPOSITO_EN_BD[datos.proposito], datos.hashToken, datos.caducaEn],
  );
}
