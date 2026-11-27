/**
 * Define las URLS (endpoints) relacionadas con autenticacion
 * y las conecta con su funcion controladora correspondiente
 */

// Framework del servidor
const express = require("express");
// Router: mini servidor de rutas que despues se monta en server.js
// con app.use("/api/auth", authRoutes)
const router = express.Router();

// Funciones controladoras con la logica real de cada endpoint
const { login, perfil } = require("../controllers/auth.controller");
// middleware que protege rutas exigiendo un token jwt valido
const verificarToken = require("../middlewares/verificarToken");

// POST /api/auth/login = iniciar sesion (ruta publica)
router.post("/login", login);

// GET /api/auth/perfil = devuelve los datos del usuario logueado
// ruta protegida: pasa primero por verificarToken
router.get("/perfil", verificarToken, perfil);

module.exports = router;