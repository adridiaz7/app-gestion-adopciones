// Una provincia tal como la devuelve GET /api/provincias.
// id = código INE (en la BD: province.id); nombre = province.name.
export interface Provincia {
  id: number;
  nombre: string;
}
