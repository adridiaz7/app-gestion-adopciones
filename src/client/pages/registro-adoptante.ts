import type { DatosRegistroAdoptante } from '../../shared/registro.js';
import { obtenerProvincias } from '../api/provincias.js';
import { registrarAdoptante } from '../api/registro.js';
import { elemento } from './dom.js';

// Pantalla 03 · Registro de adoptante (CU-01), y al terminar, 06 · Revisa tu email.
//
// El navegador comprueba el formato básico (required, type="email",
// minlength…) para avisar al momento, pero quien decide es SIEMPRE el
// servidor: estas comprobaciones se pueden saltar desde las herramientas del
// navegador. Aquí solo mejoran la experiencia.

const formulario = elemento('formulario-registro', HTMLFormElement);
const campoContrasena = elemento('contrasena', HTMLInputElement);
const campoRepetir = elemento('repetir-contrasena', HTMLInputElement);
const ayudaContrasena = elemento('ayuda-contrasena', HTMLElement);
const selectorProvincia = elemento('provincia', HTMLSelectElement);
const aviso = elemento('aviso-error', HTMLElement);
const textoAviso = elemento('texto-aviso-error', HTMLElement);
const botonEnviar = elemento('boton-crear-cuenta', HTMLButtonElement);
const pasoFormulario = elemento('paso-formulario', HTMLElement);
const pasoVerificacion = elemento('paso-verificacion', HTMLElement);
const emailEnviado = elemento('email-enviado', HTMLElement);
const enlaceCambiarTipo = elemento('enlace-cambiar-tipo', HTMLAnchorElement);

// RN-175 (los mismos límites que valida el servidor)
const LONGITUD_MINIMA = 12;
const LONGITUD_MAXIMA = 256;

function mostrarError(mensaje: string): void {
  // textContent (no innerHTML): el mensaje se muestra como texto, nunca se
  // interpreta como HTML. Así nada que venga de fuera puede inyectar código.
  textoAviso.textContent = mensaje;
  aviso.hidden = false;
  aviso.focus();
}

function ocultarError(): void {
  aviso.hidden = true;
}

// ── Provincias (RN-26) ─────────────────────────────────────────────────────
async function cargarProvincias(): Promise<void> {
  const resultado = await obtenerProvincias();
  if (!resultado.ok) {
    mostrarError('No se han podido cargar las provincias. Recarga la página.');
    return;
  }
  for (const provincia of resultado.datos) {
    selectorProvincia.add(new Option(provincia.nombre, String(provincia.id)));
  }
}

// ── Contraseña ─────────────────────────────────────────────────────────────
function actualizarAyudaContrasena(): void {
  const longitud = campoContrasena.value.length;
  const cumple = longitud >= LONGITUD_MINIMA && longitud <= LONGITUD_MAXIMA;
  ayudaContrasena.classList.toggle('cumple', cumple);
}

function comprobarQueCoinciden(): void {
  // setCustomValidity hace que el navegador trate el campo como inválido y
  // muestre este mensaje al intentar enviar el formulario.
  const coinciden = campoRepetir.value === campoContrasena.value;
  campoRepetir.setCustomValidity(coinciden ? '' : 'Las contraseñas no coinciden');
}

campoContrasena.addEventListener('input', () => {
  actualizarAyudaContrasena();
  comprobarQueCoinciden();
});
campoRepetir.addEventListener('input', comprobarQueCoinciden);

// Botones del ojo: muestran u ocultan la contraseña de su campo
for (const boton of document.querySelectorAll<HTMLButtonElement>('[data-alternar]')) {
  const campo = elemento(boton.dataset.alternar ?? '', HTMLInputElement);
  boton.addEventListener('click', () => {
    const mostrar = campo.type === 'password';
    campo.type = mostrar ? 'text' : 'password';
    boton.setAttribute('aria-pressed', String(mostrar));
    boton.setAttribute('aria-label', mostrar ? 'Ocultar contraseña' : 'Mostrar contraseña');
  });
}

// ── Envío ──────────────────────────────────────────────────────────────────
function leerDatos(): DatosRegistroAdoptante {
  const datos = new FormData(formulario);
  const texto = (campo: string): string => String(datos.get(campo) ?? '');
  // Solo se envía lo que espera la API: ni "repetir contraseña" ni la casilla
  // de los términos (el servidor rechaza cualquier campo de más).
  return {
    email: texto('email'),
    contrasena: texto('contrasena'),
    nombre: texto('nombre'),
    apellidos: texto('apellidos'),
    telefono: texto('telefono'),
    fechaNacimiento: texto('fechaNacimiento'),
    idProvincia: Number(texto('idProvincia')),
    localidad: texto('localidad'),
  };
}

function mostrarVerificacion(email: string): void {
  emailEnviado.textContent = email;
  pasoFormulario.hidden = true;
  pasoVerificacion.hidden = false;
  // Ya no tiene sentido cambiar el tipo de una cuenta que acaba de crearse
  enlaceCambiarTipo.hidden = true;
  formulario.reset();
  pasoVerificacion.focus();
}

formulario.addEventListener('submit', async (evento) => {
  // El evento submit solo llega si el navegador ha dado el formulario por
  // válido. preventDefault evita que recargue la página: lo enviamos con fetch.
  evento.preventDefault();
  ocultarError();
  botonEnviar.disabled = true;
  botonEnviar.textContent = 'Creando cuenta…';

  const resultado = await registrarAdoptante(leerDatos());

  botonEnviar.disabled = false;
  botonEnviar.textContent = 'Crear cuenta →';
  if (resultado.ok) {
    mostrarVerificacion(resultado.datos.usuario.email);
  } else {
    // El "mensaje" de la API está pensado para mostrarse tal cual (TECH_SPEC)
    mostrarError(resultado.error.mensaje);
  }
});

void cargarProvincias();
