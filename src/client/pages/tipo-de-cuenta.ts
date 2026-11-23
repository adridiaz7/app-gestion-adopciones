import { elemento } from './dom.js';

// Pantalla 02 · Tipo de cuenta. Solo decide a qué formulario ir: el rol no se
// envía a ninguna parte, lo fija el endpoint de cada formulario.
// La protectora llegará con CU-02.
const FORMULARIO_POR_TIPO: Record<string, string> = {
  adoptante: '/registro-adoptante.html',
};

const formulario = elemento('formulario-tipo', HTMLFormElement);

formulario.addEventListener('submit', (evento) => {
  evento.preventDefault();
  const tipo = new FormData(formulario).get('tipo');
  const destino = typeof tipo === 'string' ? FORMULARIO_POR_TIPO[tipo] : undefined;
  if (destino !== undefined) {
    window.location.assign(destino);
  }
});
