// Importamos mysql2 en su version promesa para usar async/await en consultas
const mysql = ("mysql2/promise");
// Cargamos las variables del archivo .env
require("dotenv").config();

// Creamos un pool (grupo reutilizable) de conexiones hacia mysql
const pool = mysql.createPool ({
    host: process.env.DB_HOST, // Servidor de base de datos (ej. localhost)
    port: process.env.DB_PORT, // Puerto de MySQL (por defecto 3306)
    user: process.env.DB_USER, // Usuario de MySQL (ej. root)
    password: process.env.DB_PASSWORD, // Contraseña de MySQL
    database: process.env.DB_NAME, // Nombre de la base de datos (FRESH_STYLE)
    waitForConnections: true, // Espera si todas las conexiones están ocupadas
    connectionsLimit: 10, // Máximo de conexiones activas simultáneas
    queueLimit: 0 // Sin límite en la cola de espera (0 = ilimitado)
});

//Exportamos
module.exports = pool;

