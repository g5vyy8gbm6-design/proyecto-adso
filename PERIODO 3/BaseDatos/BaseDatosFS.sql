-- crear base de datos
-- utf8mb4 permite guardar tildes, ñ y emojis
CREATE DATABASE IF NOT EXISTS FRESH_STYLE
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

-- usar base de datos creada
USE FRESH_STYLE;


-- ============================================================
-- DDL: CREACION DE TABLAS
-- ============================================================

-- crear tabla usuarios
-- (aqui se guardan los clientes, empleados y administradores; la contraseña se guarda cifrada)
CREATE TABLE usuarios (
    id_usuario INT NOT NULL AUTO_INCREMENT,
    nombre_usuario VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    -- password: aqui se guarda el HASH (SHA2 + salt), nunca la contraseña en texto plano
    password VARCHAR(255) NOT NULL,
    salt VARCHAR(32) NOT NULL,
    rol VARCHAR(20) NOT NULL DEFAULT 'cliente',
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    intentos_fallidos INT NOT NULL DEFAULT 0,
    bloqueado BOOLEAN NOT NULL DEFAULT FALSE,
    ultimo_acceso DATETIME NULL,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- condiciones
    CONSTRAINT pk_usuarios PRIMARY KEY (id_usuario),
    CONSTRAINT uq_usuarios_nombre UNIQUE (nombre_usuario),
    CONSTRAINT uq_usuarios_email UNIQUE (email),
    CONSTRAINT ck_usuarios_rol CHECK (rol IN ('admin', 'cliente', 'empleado'))
) ENGINE = INNODB;

-- crear tabla usuarios_auditoria
-- (registra los movimientos de seguridad: cambios de contraseña y bloqueos)
CREATE TABLE usuarios_auditoria (
    id_auditoria INT NOT NULL AUTO_INCREMENT,
    id_usuario INT NOT NULL,
    accion VARCHAR(30) NOT NULL,
    detalle VARCHAR(255) NULL,
    usuario_bd VARCHAR(100) NOT NULL,
    fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_usuarios_auditoria PRIMARY KEY (id_auditoria),
    -- relacion con usuarios
    CONSTRAINT fk_auditoria_usuario FOREIGN KEY (id_usuario)
    REFERENCES usuarios (id_usuario)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE = INNODB;

-- crear tabla categoria_establecimiento
CREATE TABLE categoria_establecimiento (
    id_categoria INT NOT NULL AUTO_INCREMENT,
    categoria VARCHAR(60) NOT NULL,
    CONSTRAINT pk_categoria_establecimiento PRIMARY KEY (id_categoria),
    CONSTRAINT uq_categoria_establecimiento_nom UNIQUE (categoria)
) ENGINE = INNODB;

-- crear tabla establecimiento
CREATE TABLE establecimiento (
    id_establecimiento INT NOT NULL AUTO_INCREMENT,
    nom_est VARCHAR(150) NOT NULL,
    direccion VARCHAR(100) NOT NULL,
    -- latitud: -90 a 90 / longitud: -180 a 180
    latitud DECIMAL(9,6) NULL,
    longitud DECIMAL(9,6) NULL,
    tel VARCHAR(20) NOT NULL,
    descri VARCHAR(300) NULL,
    id_categoria INT NOT NULL,
    -- estado: 1 = activo, 0 = inactivo
    estado INT NOT NULL DEFAULT 1,
    -- condiciones
    CONSTRAINT pk_establecimiento PRIMARY KEY (id_establecimiento),
    CONSTRAINT ck_establecimiento_latitud CHECK (latitud BETWEEN -90 AND 90),
    CONSTRAINT ck_establecimiento_longitud CHECK (longitud BETWEEN -180 AND 180),
    CONSTRAINT ck_establecimiento_estado CHECK (estado IN (0, 1)),
    -- relacion con la tabla categoria_establecimiento
    CONSTRAINT fk_establecimiento_categoria FOREIGN KEY (id_categoria)
    REFERENCES categoria_establecimiento (id_categoria)
    -- no se puede borrar una categoria si tiene establecimientos asociados
    ON DELETE RESTRICT
    -- si cambia el id de la categoria, se actualiza en establecimiento
    ON UPDATE CASCADE
) ENGINE = INNODB;

-- crear tabla administrador_establecimiento
-- (indica que usuario administrador gestiona cada establecimiento)
CREATE TABLE administrador_establecimiento (
    id_usuario INT NOT NULL,
    id_establecimiento INT NOT NULL,
    CONSTRAINT pk_administrador_establecimiento PRIMARY KEY (id_usuario, id_establecimiento),
    CONSTRAINT fk_admin_est_usuario FOREIGN KEY (id_usuario)
    REFERENCES usuarios (id_usuario)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
    CONSTRAINT fk_admin_est_establecimiento FOREIGN KEY (id_establecimiento)
    REFERENCES establecimiento (id_establecimiento)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE = INNODB;

-- crear tabla empleado
-- (el tipo de documento es un atributo de la persona, no una tabla aparte)
CREATE TABLE empleado (
    id_empleado INT NOT NULL AUTO_INCREMENT,
    nom_empleado VARCHAR(150) NOT NULL,
    ape_empleado VARCHAR(150) NOT NULL,
    tipo_documento VARCHAR(20) NOT NULL,
    doc_emp VARCHAR(25) NOT NULL,
    cor_emp VARCHAR(150) NOT NULL,
    tel_emp VARCHAR(20) NOT NULL,
    -- ser_emp: servicio o cargo principal del empleado
    ser_emp VARCHAR(100) NOT NULL,
    id_establecimiento INT NOT NULL,
    id_usuario INT NOT NULL,
    -- condiciones
    CONSTRAINT pk_empleado PRIMARY KEY (id_empleado),
    CONSTRAINT ck_empleado_tipo_documento CHECK (tipo_documento IN ('CC', 'CE', 'TI', 'Pasaporte')),
    -- documento, correo y usuario no se pueden repetir
    CONSTRAINT uq_empleado_doc_emp UNIQUE (doc_emp),
    CONSTRAINT uq_empleado_cor_emp UNIQUE (cor_emp),
    CONSTRAINT uq_empleado_usuario UNIQUE (id_usuario),
    -- relacion con establecimiento
    CONSTRAINT fk_empleado_establecimiento FOREIGN KEY (id_establecimiento)
    REFERENCES establecimiento (id_establecimiento)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
    -- relacion con usuarios
    CONSTRAINT fk_empleado_usuario FOREIGN KEY (id_usuario)
    REFERENCES usuarios (id_usuario)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE = INNODB;

-- crear tabla horarios
CREATE TABLE horarios (
    id_horario INT NOT NULL AUTO_INCREMENT,
    id_empleado INT NOT NULL,
    dia_semana VARCHAR(15) NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    -- estado: 1 = activo, 0 = inactivo
    estado TINYINT(1) NOT NULL DEFAULT 1,
    -- condiciones
    CONSTRAINT pk_horarios PRIMARY KEY (id_horario),
    CONSTRAINT ck_horarios_dia CHECK (dia_semana IN ('Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado', 'Domingo')),
    CONSTRAINT ck_horarios_horas CHECK (hora_fin > hora_inicio),
    CONSTRAINT ck_horarios_estado CHECK (estado IN (0, 1)),
    -- relacion con empleado
    CONSTRAINT fk_horarios_empleado FOREIGN KEY (id_empleado)
    REFERENCES empleado (id_empleado)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE = INNODB;

-- crear tabla cliente
CREATE TABLE cliente (
    id_cliente INT NOT NULL AUTO_INCREMENT,
    nom_cli VARCHAR(150) NOT NULL,
    ape_cli VARCHAR(150) NOT NULL,
    tel_cli VARCHAR(20) NOT NULL,
    cor_cli VARCHAR(150) NOT NULL,
    tipo_documento VARCHAR(20) NOT NULL,
    doc_cli VARCHAR(25) NOT NULL,
    id_usuario INT NOT NULL,
    -- condiciones
    CONSTRAINT pk_cliente PRIMARY KEY (id_cliente),
    CONSTRAINT ck_cliente_tipo_documento CHECK (tipo_documento IN ('CC', 'CE', 'TI', 'Pasaporte')),
    CONSTRAINT uq_cliente_cor_cli UNIQUE (cor_cli),
    CONSTRAINT uq_cliente_doc_cli UNIQUE (doc_cli),
    CONSTRAINT uq_cliente_usuario UNIQUE (id_usuario),
    -- relacion con usuarios
    CONSTRAINT fk_cliente_usuario FOREIGN KEY (id_usuario)
    REFERENCES usuarios (id_usuario)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE = INNODB;

-- crear tabla servicio
-- (cada servicio lo ofrece un empleado)
CREATE TABLE servicio (
    id_servicio INT NOT NULL AUTO_INCREMENT,
    servicio VARCHAR(60) NOT NULL,
    precio DECIMAL(10,2) NOT NULL,
    id_empleado INT NOT NULL,
    CONSTRAINT pk_servicio PRIMARY KEY (id_servicio),
    CONSTRAINT ck_servicio_precio CHECK (precio >= 0),
    -- un empleado no puede repetir el mismo servicio
    CONSTRAINT uq_servicio_empleado UNIQUE (servicio, id_empleado),
    -- relacion con empleado
    CONSTRAINT fk_servicio_empleado FOREIGN KEY (id_empleado)
    REFERENCES empleado (id_empleado)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE = INNODB;

-- crear tabla reserva
CREATE TABLE reserva (
    id_reserva INT NOT NULL AUTO_INCREMENT,
    cos_total DECIMAL(10,2) NOT NULL DEFAULT 0,
    f_res DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    id_cliente INT NOT NULL,
    id_servicio INT NOT NULL,
    est_res VARCHAR(20) NOT NULL DEFAULT 'pendiente',
    -- condiciones
    CONSTRAINT pk_reserva PRIMARY KEY (id_reserva),
    CONSTRAINT ck_reserva_cos_total CHECK (cos_total >= 0),
    CONSTRAINT ck_reserva_horas CHECK (hora_fin > hora_inicio),
    -- estados permitidos: pendiente, confirmada, cancelada, completada
    CONSTRAINT ck_reserva_estado CHECK (est_res IN ('pendiente', 'confirmada', 'cancelada', 'completada')),
    -- relacion con cliente
    CONSTRAINT fk_reserva_cliente FOREIGN KEY (id_cliente)
    REFERENCES cliente (id_cliente)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
    -- relacion con servicio
    CONSTRAINT fk_reserva_servicio FOREIGN KEY (id_servicio)
    REFERENCES servicio (id_servicio)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE = INNODB;

CREATE INDEX idx_reserva_fecha_estado ON reserva (f_res, est_res);
CREATE INDEX idx_reserva_cliente ON reserva (id_cliente);
CREATE INDEX idx_reserva_servicio ON reserva (id_servicio);
CREATE INDEX idx_horarios_empleado_dia ON horarios (id_empleado, dia_semana, estado);
CREATE INDEX idx_cliente_usuario ON cliente (id_usuario);
CREATE INDEX idx_empleado_usuario ON empleado (id_usuario);

-- ============================================================
-- SEGURIDAD: PROCEDIMIENTOS Y TRIGGER
-- ============================================================

DELIMITER //
CREATE TRIGGER tgr_validar_administrador_establecimiento
BEFORE INSERT ON administrador_establecimiento
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM usuarios
        WHERE id_usuario = NEW.id_usuario AND rol = 'admin'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El usuario administrador debe tener el rol admin';
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER tgr_validar_administrador_establecimiento_update
BEFORE UPDATE ON administrador_establecimiento
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM usuarios
        WHERE id_usuario = NEW.id_usuario AND rol = 'admin'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El usuario administrador debe tener el rol admin';
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER tgr_validar_empleado
BEFORE INSERT ON empleado
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM usuarios
        WHERE id_usuario = NEW.id_usuario AND rol = 'empleado'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El empleado debe tener el rol empleado';
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER tgr_validar_empleado_update
BEFORE UPDATE ON empleado
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM usuarios
        WHERE id_usuario = NEW.id_usuario AND rol = 'empleado'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El empleado debe tener el rol empleado';
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER tgr_validar_horario_insert
BEFORE INSERT ON horarios
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM horarios h
        WHERE h.id_empleado = NEW.id_empleado
          AND h.dia_semana = NEW.dia_semana
          AND h.estado = 1
          AND NEW.estado = 1
          AND NEW.hora_inicio < h.hora_fin
          AND NEW.hora_fin > h.hora_inicio
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El horario se superpone con otro horario del empleado';
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER tgr_validar_horario_update
BEFORE UPDATE ON horarios
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM horarios h
        WHERE h.id_horario <> NEW.id_horario
          AND h.id_empleado = NEW.id_empleado
          AND h.dia_semana = NEW.dia_semana
          AND h.estado = 1
          AND NEW.estado = 1
          AND NEW.hora_inicio < h.hora_fin
          AND NEW.hora_fin > h.hora_inicio
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El horario se superpone con otro horario del empleado';
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER tgr_validar_cliente
BEFORE INSERT ON cliente
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM usuarios
        WHERE id_usuario = NEW.id_usuario AND rol = 'cliente'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El cliente debe tener el rol cliente';
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER tgr_validar_cliente_update
BEFORE UPDATE ON cliente
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM usuarios
        WHERE id_usuario = NEW.id_usuario AND rol = 'cliente'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El cliente debe tener el rol cliente';
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER tgr_validar_reserva_insert
BEFORE INSERT ON reserva
FOR EACH ROW
BEGIN
    DECLARE v_id_empleado INT;
    DECLARE v_dia VARCHAR(15);
    DECLARE v_precio DECIMAL(10,2);

    SELECT id_empleado, precio INTO v_id_empleado, v_precio
    FROM servicio
    WHERE id_servicio = NEW.id_servicio;

    SET v_dia = CASE DAYOFWEEK(NEW.f_res)
        WHEN 1 THEN 'Domingo'
        WHEN 2 THEN 'Lunes'
        WHEN 3 THEN 'Martes'
        WHEN 4 THEN 'Miercoles'
        WHEN 5 THEN 'Jueves'
        WHEN 6 THEN 'Viernes'
        WHEN 7 THEN 'Sabado'
    END;

    SET NEW.cos_total = v_precio;

    IF NOT EXISTS (
        SELECT 1
        FROM horarios
        WHERE id_empleado = v_id_empleado
          AND dia_semana = v_dia
          AND estado = 1
          AND NEW.hora_inicio >= hora_inicio
          AND NEW.hora_fin <= hora_fin
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La reserva esta fuera del horario del empleado';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM reserva r
        INNER JOIN servicio s ON s.id_servicio = r.id_servicio
        WHERE s.id_empleado = v_id_empleado
          AND r.f_res = NEW.f_res
          AND r.est_res IN ('pendiente', 'confirmada')
          AND NEW.hora_inicio < r.hora_fin
          AND NEW.hora_fin > r.hora_inicio
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El empleado ya tiene una reserva en ese horario';
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER tgr_validar_reserva_update
BEFORE UPDATE ON reserva
FOR EACH ROW
BEGIN
    DECLARE v_id_empleado INT;
    DECLARE v_dia VARCHAR(15);
    DECLARE v_precio DECIMAL(10,2);

    SELECT id_empleado, precio INTO v_id_empleado, v_precio
    FROM servicio
    WHERE id_servicio = NEW.id_servicio;

    SET v_dia = CASE DAYOFWEEK(NEW.f_res)
        WHEN 1 THEN 'Domingo'
        WHEN 2 THEN 'Lunes'
        WHEN 3 THEN 'Martes'
        WHEN 4 THEN 'Miercoles'
        WHEN 5 THEN 'Jueves'
        WHEN 6 THEN 'Viernes'
        WHEN 7 THEN 'Sabado'
    END;

    SET NEW.cos_total = v_precio;

    IF NOT EXISTS (
        SELECT 1
        FROM horarios
        WHERE id_empleado = v_id_empleado
          AND dia_semana = v_dia
          AND estado = 1
          AND NEW.hora_inicio >= hora_inicio
          AND NEW.hora_fin <= hora_fin
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La reserva esta fuera del horario del empleado';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM reserva r
        INNER JOIN servicio s ON s.id_servicio = r.id_servicio
        WHERE r.id_reserva <> NEW.id_reserva
          AND s.id_empleado = v_id_empleado
          AND r.f_res = NEW.f_res
          AND r.est_res IN ('pendiente', 'confirmada')
          AND NEW.hora_inicio < r.hora_fin
          AND NEW.hora_fin > r.hora_inicio
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El empleado ya tiene una reserva en ese horario';
    END IF;
END //
DELIMITER ;

-- registrar usuario
DELIMITER //
CREATE PROCEDURE sp_registrar_usuario(
    IN p_nombre_usuario VARCHAR(50),
    IN p_email VARCHAR(100),
    IN p_password VARCHAR(100),
    IN p_rol VARCHAR(20)
)
BEGIN
    DECLARE v_salt CHAR(32);
    IF CHAR_LENGTH(p_password) < 8
    OR CAST(p_password AS BINARY) = CAST(LOWER(p_password) AS BINARY)
    OR p_password NOT REGEXP '[0-9]' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La contraseña debe tener minimo 8 caracteres, una mayuscula y un numero';
    END IF;

    SET v_salt = LEFT(SHA2(CONCAT(UUID(), RAND(), NOW(6)), 256), 32);

    INSERT INTO usuarios (nombre_usuario, email, password, salt, rol)
    VALUES (
        p_nombre_usuario,
        p_email,
        SHA2(CONCAT(v_salt, p_password), 256),
        v_salt,
        p_rol
    );
END //
DELIMITER ;

-- login
DELIMITER //
CREATE PROCEDURE sp_login(
    IN p_nombre_usuario VARCHAR(50),
    IN p_password VARCHAR(100),
    OUT p_resultado VARCHAR(100)
)
BEGIN
    DECLARE v_id INT DEFAULT NULL;
    DECLARE v_hash CHAR(64);
    DECLARE v_salt CHAR(32);
    DECLARE v_bloqueado BOOLEAN;
    DECLARE v_intentos INT;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_id = NULL;

    SELECT id_usuario, password, salt, bloqueado, intentos_fallidos
    INTO v_id, v_hash, v_salt, v_bloqueado, v_intentos
    FROM usuarios
    WHERE nombre_usuario = p_nombre_usuario AND activo = TRUE;

    IF v_id IS NULL THEN

        SET p_resultado = 'usuario o contraseña incorrectos';

    ELSEIF v_bloqueado = TRUE THEN

        SET p_resultado = 'Usuario bloqueado. Contacte al administrador';

    ELSEIF v_hash = SHA2(CONCAT(v_salt, p_password), 256) THEN

        UPDATE usuarios
        SET intentos_fallidos = 0,
        ultimo_acceso = NOW()
        WHERE id_usuario = v_id;

        SET p_resultado = 'Acceso concedido';

    ELSE

        UPDATE usuarios
        SET intentos_fallidos = v_intentos + 1,
        bloqueado = (v_intentos + 1 >= 3)
        WHERE id_usuario = v_id;
        SET p_resultado = 'usuario o contraseña incorrectos';

    END IF;
END //
DELIMITER ;

-- cambiar contraseña
DELIMITER //
CREATE PROCEDURE sp_cambiar_password(
    IN p_nombre_usuario VARCHAR(50),
    IN p_password_actual VARCHAR(100),
    IN p_password_nueva VARCHAR(100),
    OUT p_resultado VARCHAR(100)
)
BEGIN
    DECLARE v_salt CHAR(32);
    DECLARE v_salt_nuevo CHAR(32);

    SELECT salt INTO v_salt
    FROM usuarios
    WHERE nombre_usuario = p_nombre_usuario;

    IF NOT EXISTS (SELECT 1 FROM usuarios
        WHERE nombre_usuario = p_nombre_usuario
        AND password = SHA2(CONCAT(v_salt, p_password_actual), 256)) THEN
        SET p_resultado = 'la contraseña actual no es correcta';
    ELSEIF CHAR_LENGTH(p_password_nueva) < 8
        OR CAST(p_password_nueva AS BINARY) = CAST(LOWER(p_password_nueva) AS BINARY)
        OR p_password_nueva NOT REGEXP '[0-9]' THEN
        SET p_resultado = 'la nueva contraseña no cumple con la politica';
    ELSE
        SET v_salt_nuevo = LEFT(SHA2(CONCAT(UUID(), RAND(), NOW(6)), 256), 32);
        UPDATE usuarios
        SET salt = v_salt_nuevo,
            password = SHA2(CONCAT(v_salt_nuevo, p_password_nueva), 256)
        WHERE nombre_usuario = p_nombre_usuario;
        SET p_resultado = 'contraseña actualizada';
    END IF;
END //
DELIMITER ;

-- trigger de auditoria
DELIMITER //
CREATE TRIGGER tgr_usuarios_auditoria
AFTER UPDATE ON usuarios
FOR EACH ROW
BEGIN
    IF NEW.password <> OLD.password THEN
        INSERT INTO usuarios_auditoria (id_usuario, accion, detalle, usuario_bd)
        VALUES (NEW.id_usuario, 'CAMBIO_PASSWORD', 'se cambio la contraseña', CURRENT_USER());
    END IF;

    IF NEW.bloqueado = TRUE AND OLD.bloqueado = FALSE THEN
        INSERT INTO usuarios_auditoria (id_usuario, accion, detalle, usuario_bd)
        VALUES (NEW.id_usuario, 'BLOQUEO', 'bloqueado por 3 intentos fallidos', CURRENT_USER());
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_desbloquear_usuario(
    IN p_nombre_usuario VARCHAR(50)
)
BEGIN
    UPDATE usuarios
    SET bloqueado = FALSE,
        intentos_fallidos = 0
    WHERE nombre_usuario = p_nombre_usuario;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER tgr_validar_rol_usuario_insert
BEFORE INSERT ON usuarios
FOR EACH ROW
BEGIN
    IF NEW.rol NOT IN ('admin', 'cliente', 'empleado') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Rol de usuario no valido';
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER tgr_validar_rol_usuario_update
BEFORE UPDATE ON usuarios
FOR EACH ROW
BEGIN
    IF NEW.rol NOT IN ('admin', 'cliente', 'empleado') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Rol de usuario no valido';
    END IF;
END //
DELIMITER ;

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


-- ============================================================
-- PRUEBAS DE SEGURIDAD
-- ============================================================

-- Prueba de usuario duplicado: se espera que el procedimiento devuelva un error
CALL sp_registrar_usuario('juan_perez', 'juan.perez@gmail.com', 'Cliente#2026', 'cliente');

-- Prueba de contrasena debil: se espera que el procedimiento la rechace
CALL sp_registrar_usuario('debil', 'debil@gmail.com', '12345', 'cliente');

-- Inicio de sesion correcto
CALL sp_login('kylian_gonzalez', 'Cliente#2026', @resultado);
SELECT @resultado AS login_correcto;

-- Tres intentos fallidos bloquean al usuario
CALL sp_login('juan_perez', 'clave_mala', @r1);
CALL sp_login('juan_perez', 'clave_mala', @r2);
CALL sp_login('juan_perez', 'clave_mala', @r3);
CALL sp_login('juan_perez', 'Cliente#2026', @r4);
SELECT @r1, @r2, @r3, @r4;

SELECT nombre_usuario, intentos_fallidos, bloqueado
FROM usuarios;

-- Cambio de contrasena
CALL sp_cambiar_password('maria_lopez', 'Cliente#2026', 'NuevaClave2026', @r);
SELECT @r AS cambio;

-- Evidencia de auditoria (bloqueo y cambio de contraseña)
SELECT * FROM usuarios_auditoria;

-- El administrador desbloquea al usuario
CALL sp_desbloquear_usuario('juan_perez');