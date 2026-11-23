import type { DatosRegistroAdoptante, RespuestaRegistro } from '../../shared/registro.js';
import { pedirApi, type Resultado } from './peticion.js';

// CU-01
export function registrarAdoptante(
  datos: DatosRegistroAdoptante,
): Promise<Resultado<RespuestaRegistro>> {
  return pedirApi<RespuestaRegistro>('/api/registro/adoptante', {
    method: 'POST',
    body: JSON.stringify(datos),
  });
}
