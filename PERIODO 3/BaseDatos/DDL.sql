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