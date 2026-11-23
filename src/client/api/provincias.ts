import type { Provincia } from '../../shared/provincia.js';
import { pedirApi, type Resultado } from './peticion.js';

export function obtenerProvincias(): Promise<Resultado<Provincia[]>> {
  return pedirApi<Provincia[]>('/api/provincias');
}
