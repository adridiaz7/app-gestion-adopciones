// Busca un elemento por id y comprueba su tipo. Si el HTML y el TypeScript
// dejan de coincidir (un id renombrado), falla al cargar la página con un
// mensaje claro, en vez de un "null" misterioso más tarde.
export function elemento<T extends HTMLElement>(
  id: string,
  tipo: new () => T,
): T {
  const encontrado = document.getElementById(id);
  if (!(encontrado instanceof tipo)) {
    throw new Error(`Falta el elemento #${id} (${tipo.name}) en el HTML`);
  }
  return encontrado;
}
