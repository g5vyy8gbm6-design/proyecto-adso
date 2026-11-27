// Librería para verificar tokens JWT
const jwt = require("jsonwebtoken");
require("dotenv").config();

// req: petición entrante | res: respuesta | next: deja pasar a la ruta
function verificarToken(req, res, next) {
    // El frontend envía el token en el header: Authorization: Bearer <token>
    const authHeader = req.headers["authorization"];

    // Si no viene el header, rechazamos la petición
    if (!authHeader) {
        return res.status(401).json({ mensaje: "No se envió un token de autenticación" });
    }

    // Separamos "Bearer <token>" por el espacio y tomamos la segunda parte
    const token = authHeader.split(" ")[1];

    // Si no viene el token después de "Bearer", rechazamos
    if (!token) {
        return res.status(401).json({ mensaje: "Formato de token inválido" });
    }

    try {
        // Verificamos el token con la clave secreta de FRESH_STYLE (.env)
        const datosUsuario = jwt.verify(token, process.env.JWT_SECRET);

        // Guardamos los datos del usuario (id_usuario, nombre_usuario, rol)
        // para usarlos en los controladores de FRESH_STYLE
        req.usuario = datosUsuario;

        // Todo bien: continuamos con la ruta
        next();
    } catch (error) {
        // Si el token venció o fue alterado, devolvemos error 401
        return res.status(401).json({ mensaje: "Token inválido o expirado" });
    }
}

// Exportamos la función
module.exports = verificarToken;