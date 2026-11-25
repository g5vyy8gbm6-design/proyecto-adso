-- ============================================================
-- DML: REGISTROS
-- ============================================================

-- Categorias de establecimientos
INSERT INTO categoria_establecimiento (categoria) VALUES
('Barberia'), ('Spa'), ('Manicure'), ('Peluqueria');


-- Agregamos establecimientos
INSERT INTO establecimiento (nom_est, direccion, latitud, longitud, tel, descri, id_categoria) VALUES
("Barberia Elite", "calle 100", NULL, NULL, "3001234567", "Servicios de barberia", 1),
("Spa Relax", "Calle 57", NULL, NULL, "3002222222", "Servicios de spa", 2),
("Arte en las Manos", "calle 22", NULL, NULL, "3137895439", "Servicios de manicure", 3),
("La Tijera Urbana", "calle 41", NULL, NULL, "3206778891", "Servicios de peluqueria", 4);


-- Registramos los usuarios con el procedimiento (la contraseña queda cifrada con su salt)
-- Administradores de los establecimientos
CALL sp_registrar_usuario('admin_elite', 'admin.elite@freshstyle.com', 'Admin#2026', 'admin');
CALL sp_registrar_usuario('admin_relax', 'admin.relax@freshstyle.com', 'Admin#2026', 'admin');
CALL sp_registrar_usuario('admin_manos', 'admin.manos@freshstyle.com', 'Admin#2026', 'admin');
CALL sp_registrar_usuario('admin_tijera', 'admin.tijera@freshstyle.com', 'Admin#2026', 'admin');

-- Empleados
CALL sp_registrar_usuario('juan_rabelo', 'juan.rabelo@freshstyle.com', 'Empleado#2026', 'empleado');
CALL sp_registrar_usuario('camilo_vargas', 'camilo.vargas@freshstyle.com', 'Empleado#2026', 'empleado');
CALL sp_registrar_usuario('lucia_gomez', 'lucia.gomez@freshstyle.com', 'Empleado#2026', 'empleado');
CALL sp_registrar_usuario('ana_martinez', 'ana.martinez@freshstyle.com', 'Empleado#2026', 'empleado');

-- Clientes
CALL sp_registrar_usuario('kylian_gonzalez', 'kylian@gmail.com', 'Cliente#2026', 'cliente');
CALL sp_registrar_usuario('juan_perez', 'juan.perez@gmail.com', 'Cliente#2026', 'cliente');
CALL sp_registrar_usuario('carlos_martinez', 'carlos.martinez@gmail.com', 'Cliente#2026', 'cliente');
CALL sp_registrar_usuario('andres_garcia', 'andres.garcia@gmail.com', 'Cliente#2026', 'cliente');
CALL sp_registrar_usuario('diego_ramirez', 'diego.ramirez@gmail.com', 'Cliente#2026', 'cliente');
CALL sp_registrar_usuario('miguel_castro', 'miguel.castro@gmail.com', 'Cliente#2026', 'cliente');
CALL sp_registrar_usuario('laura_lopez', 'laura.lopez@gmail.com', 'Cliente#2026', 'cliente');
CALL sp_registrar_usuario('maria_lopez', 'maria@gmail.com', 'Cliente#2026', 'cliente');
CALL sp_registrar_usuario('camila_torres', 'camila.torres@gmail.com', 'Cliente#2026', 'cliente');
CALL sp_registrar_usuario('maria_rodriguez', 'maria.rodriguez@gmail.com', 'Cliente#2026', 'cliente');
CALL sp_registrar_usuario('sofia_herrera', 'sofia.herrera@gmail.com', 'Cliente#2026', 'cliente');


-- Administrador de cada establecimiento
INSERT INTO administrador_establecimiento (id_usuario, id_establecimiento) VALUES
((SELECT id_usuario FROM usuarios WHERE nombre_usuario = 'admin_elite'), 1),
((SELECT id_usuario FROM usuarios WHERE nombre_usuario = 'admin_relax'), 2),
((SELECT id_usuario FROM usuarios WHERE nombre_usuario = 'admin_manos'), 3),
((SELECT id_usuario FROM usuarios WHERE nombre_usuario = 'admin_tijera'), 4);


-- Insertamos los empleados
INSERT INTO empleado (nom_empleado, ape_empleado, tipo_documento, doc_emp, cor_emp, tel_emp, ser_emp, id_establecimiento, id_usuario) VALUES
("Juan", "Rabelo", "CC", "1001001001", "juan.rabelo@freshstyle.com", "3012345678", "Barbero", 1,
    (SELECT id_usuario FROM usuarios WHERE nombre_usuario = 'juan_rabelo')),
("Camilo", "Vargas", "CC", "1001001002", "camilo.vargas@freshstyle.com", "3034523456", "Masajista", 2,
    (SELECT id_usuario FROM usuarios WHERE nombre_usuario = 'camilo_vargas')),
("Lucia", "Gomez", "CC", "1001001003", "lucia.gomez@freshstyle.com", "3028765432", "Manicurista", 3,
    (SELECT id_usuario FROM usuarios WHERE nombre_usuario = 'lucia_gomez')),
("Ana", "Martinez", "CC", "1001001004", "ana.martinez@freshstyle.com", "3023456891", "Peluquera", 4,
    (SELECT id_usuario FROM usuarios WHERE nombre_usuario = 'ana_martinez'));


-- Insertamos los horarios de los empleados
INSERT INTO horarios (id_empleado, dia_semana, hora_inicio, hora_fin, estado) VALUES
(1, "Lunes", "08:00:00", "17:00:00", 1),
(1, "Miercoles", "08:00:00", "17:00:00", 1),
(1, "Viernes", "08:00:00", "17:00:00", 1),
(2, "Martes", "09:00:00", "18:00:00", 1),
(2, "Jueves", "09:00:00", "18:00:00", 1),
(2, "Sabado", "09:00:00", "14:00:00", 1),
(3, "Lunes", "10:00:00", "18:00:00", 1),
(3, "Miercoles", "10:00:00", "18:00:00", 1),
(3, "Viernes", "10:00:00", "18:00:00", 1),
(4, "Martes", "08:00:00", "17:00:00", 1),
(4, "Jueves", "08:00:00", "17:00:00", 1),
(4, "Sabado", "08:00:00", "15:00:00", 1);


-- Insertamos los clientes
INSERT INTO cliente (nom_cli, ape_cli, tel_cli, cor_cli, tipo_documento, doc_cli, id_usuario) VALUES
("Kylian", "Gonzalez", "3001234567", "kylian@gmail.com", "CC", "1002001001",
    (SELECT id_usuario FROM usuarios WHERE nombre_usuario = 'kylian_gonzalez')),
("Juan", "Perez", "3012345678", "juan.perez@gmail.com", "CC", "1002001002",
    (SELECT id_usuario FROM usuarios WHERE nombre_usuario = 'juan_perez')),
("Carlos", "Martinez", "3034567890", "carlos.martinez@gmail.com", "CC", "1002001003",
    (SELECT id_usuario FROM usuarios WHERE nombre_usuario = 'carlos_martinez')),
("Andres", "Garcia", "3056789012", "andres.garcia@gmail.com", "CC", "1002001004",
    (SELECT id_usuario FROM usuarios WHERE nombre_usuario = 'andres_garcia')),
("Diego", "Ramirez", "3078901234", "diego.ramirez@gmail.com", "CC", "1002001005",
    (SELECT id_usuario FROM usuarios WHERE nombre_usuario = 'diego_ramirez')),
("Miguel", "Castro", "3090123456", "miguel.castro@gmail.com", "CC", "1002001006",
    (SELECT id_usuario FROM usuarios WHERE nombre_usuario = 'miguel_castro')),
("Laura", "Lopez", "3045678901", "laura.lopez@gmail.com", "CC", "1002001007",
    (SELECT id_usuario FROM usuarios WHERE nombre_usuario = 'laura_lopez')),
("Maria", "Lopez", "3101234567", "maria@gmail.com", "CC", "1002001008",
    (SELECT id_usuario FROM usuarios WHERE nombre_usuario = 'maria_lopez')),
("Camila", "Torres", "3067890123", "camila.torres@gmail.com", "CC", "1002001009",
    (SELECT id_usuario FROM usuarios WHERE nombre_usuario = 'camila_torres')),
("Maria", "Rodriguez", "3023456789", "maria.rodriguez@gmail.com", "CC", "1002001010",
    (SELECT id_usuario FROM usuarios WHERE nombre_usuario = 'maria_rodriguez')),
("Sofia", "Herrera", "3089012345", "sofia.herrera@gmail.com", "CC", "1002001011",
    (SELECT id_usuario FROM usuarios WHERE nombre_usuario = 'sofia_herrera'));


-- Insertamos los servicios (cada uno con el empleado que lo ofrece)
INSERT INTO servicio (servicio, precio, id_empleado) VALUES
("Corte de cabello", 20000, 1),
("Corte y barba", 35000, 1),
("Arreglo de barba", 18000, 1),
("Corte y cejas", 25000, 1),
("Masaje relajante", 60000, 2),
("Masaje descontracturante", 65000, 2),
("Facial hidratante", 55000, 2),
("Exfoliacion corporal", 55000, 2),
("Manicure clasico", 30000, 3),
("Manicure semipermanente", 45000, 3),
("Pedicure", 40000, 3),
("Pedicure spa", 55000, 3),
("Corte de cabello", 45000, 4),
("Corte y cepillado", 45000, 4),
("Tintura", 80000, 4),
("Mechas", 80000, 4);


-- Insertamos las reservas
INSERT INTO reserva (cos_total, f_res, hora_inicio, hora_fin, id_cliente, id_servicio, est_res) VALUES
(20000, "2026-11-25", "09:00:00", "10:00:00", 1, 1, "pendiente"),
(65000, "2026-11-26", "10:00:00", "11:30:00", 2, 6, "confirmada"),
(35000, "2026-11-27", "11:00:00", "12:00:00", 3, 2, "completada"),
(45000, "2026-11-28", "14:00:00", "15:00:00", 4, 14, "pendiente"),
(60000, "2026-11-28", "10:00:00", "11:30:00", 5, 7, "confirmada"),
(80000, "2026-11-28", "09:00:00", "11:00:00", 6, 15, "cancelada"),
(18000, "2026-11-27", "10:00:00", "10:30:00", 7, 3, "confirmada"),
(55000, "2026-11-28", "12:00:00", "13:30:00", 8, 8, "pendiente"),
(55000, "2026-11-30", "10:00:00", "11:30:00", 9, 12, "completada"),
(80000, "2026-12-01", "10:00:00", "12:00:00", 10, 15, "confirmada"),
(45000, "2026-12-01", "14:00:00", "15:00:00", 11, 14, "cancelada");


-- ============================================================
-- CONSULTAS
-- ============================================================

-- Ver todos los usuarios (se muestra el hash y el salt, no la contraseña en texto plano)
SELECT id_usuario, nombre_usuario, email, rol, salt, password
FROM usuarios;

-- Ver todos los clientes con su usuario
SELECT c.id_cliente, c.nom_cli, c.ape_cli, c.tipo_documento, c.doc_cli,
c.tel_cli, c.cor_cli, u.nombre_usuario, u.rol
FROM cliente c
INNER JOIN usuarios u ON c.id_usuario = u.id_usuario;

-- Ver empleados con su establecimiento y su usuario
SELECT e.nom_empleado, e.ape_empleado, e.ser_emp, es.nom_est, u.nombre_usuario
FROM empleado e
INNER JOIN establecimiento es ON e.id_establecimiento = es.id_establecimiento
INNER JOIN usuarios u ON e.id_usuario = u.id_usuario;

-- Ver establecimientos y su categoria
SELECT e.nom_est, c.categoria
FROM establecimiento e
INNER JOIN categoria_establecimiento c ON e.id_categoria = c.id_categoria;

-- Ver administradores y el establecimiento que administran
SELECT u.nombre_usuario, e.nom_est
FROM administrador_establecimiento ae
INNER JOIN usuarios u ON ae.id_usuario = u.id_usuario
INNER JOIN establecimiento e ON ae.id_establecimiento = e.id_establecimiento;

-- Ver horarios de los empleados
SELECT e.nom_empleado, e.ape_empleado, h.dia_semana, h.hora_inicio, h.hora_fin
FROM horarios h
INNER JOIN empleado e ON h.id_empleado = e.id_empleado;

-- Ver reservas con el cliente, el servicio, el empleado y su estado
SELECT r.id_reserva, r.f_res, r.hora_inicio, r.hora_fin,
c.nom_cli, c.ape_cli, s.servicio, s.precio,
e.nom_empleado, e.ape_empleado, r.est_res, r.cos_total
FROM reserva r
INNER JOIN cliente c ON r.id_cliente = c.id_cliente
INNER JOIN servicio s ON r.id_servicio = s.id_servicio
INNER JOIN empleado e ON s.id_empleado = e.id_empleado;

-- Ver servicios y el empleado que los ofrece
SELECT s.servicio, s.precio, e.nom_empleado, e.ape_empleado, es.nom_est
FROM servicio s
INNER JOIN empleado e ON s.id_empleado = e.id_empleado
INNER JOIN establecimiento es ON e.id_establecimiento = es.id_establecimiento;
