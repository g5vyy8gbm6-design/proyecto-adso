// Framework para crear el servidor HTTP y definir rutas
const express = require("express");

// Middleware que habilita CORS (peticiones desde otro origen o puerto, como el frontend)
const cors = require("cors");

// Lee el archivo .env y carga sus valores en process.env (PORT, DB_NAME, JWT_SECRET, etc.)
require("dotenv").config();

// Importamos el router con los endpoints de autenticación (registro, login, perfil)
const authRoutes = require("./routes/auth.routes");

// Importamos las rutas del dominio de FRESH_STYLE (establecimientos, servicios, reservas)
const freshStyleRoutes = require("./routes/freshStyle.routes");

// Creamos la aplicación Express
const app = express();

// cors() permite que el frontend (que corre en otro puerto) pueda hacer
// peticiones a este backend de FRESH_STYLE sin que el navegador lo bloquee
app.use(cors());

// express.json() le enseña a Express a leer el body de las peticiones
// cuando viene en formato JSON (así podemos leer req.body.nombre_usuario, req.body.email, etc.)
app.use(express.json());

// Ruta de salud simple, útil para probar que la API de FRESH_STYLE está viva
app.get("/", (req, res) => {
    res.json({ mensaje: "API de FRESH_STYLE funcionando correctamente" });
});

// Todas las rutas que empiecen con /api/auth se resuelven en auth.routes.js
app.use("/api/auth", authRoutes);

// Todas las rutas del negocio (establecimientos, horarios, servicios, reservas)
app.use("/api", freshStyleRoutes);

// Middleware para rutas que no existen (404)
app.use((req, res) => {
    res.status(404).json({ mensaje: "Ruta no encontrada en FRESH_STYLE" });
});

// Tomamos el puerto desde .env o 4000 si no está definido
const PORT = process.env.PORT || 4000;

// Arranca el servidor: a partir de aquí Express queda escuchando
// peticiones HTTP en el puerto indicado hasta que se detenga el proceso
app.listen(PORT, () => {
    // Este callback se ejecuta una vez cuando el servidor está listo
    console.log(`Servidor backend escuchando en http://localhost:${PORT}`);
});