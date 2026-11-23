// Envío de emails detrás de una interfaz: el resto del código no sabe cómo
// se envían. El envío real es una decisión pendiente (CLAUDE.md); mientras
// tanto se usa la implementación de consola, y en los tests un doble que
// guarda lo enviado para poder comprobarlo.
export interface EnviadorEmail {
  enviarVerificacionEmail(destinatario: string, enlace: string): Promise<void>;
}

// Solo para desarrollo: escribe el enlace en la consola del servidor, para
// poder copiarlo y abrirlo en el navegador.
export const enviadorEmailDeConsola: EnviadorEmail = {
  enviarVerificacionEmail(destinatario, enlace) {
    console.log(`[email] Para ${destinatario} · Enlace de verificación: ${enlace}`);
    return Promise.resolve();
  },
};
