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

--procedimiento para desbloquear usuarios
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