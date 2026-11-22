// Punto de entrada: lee la configuración y arranca el servidor.
// Las variables llegan desde .env gracias a `--env-file` (ver scripts de package.json).
import { crearApp } from './app.js';
import { cargarConfiguracion } from './config/config.js';

const configuracion = cargarConfiguracion(process.env);
const app = crearApp();

app.listen(configuracion.puerto, () => {
  console.log(`Servidor escuchando en http://localhost:${configuracion.puerto}`);
});
